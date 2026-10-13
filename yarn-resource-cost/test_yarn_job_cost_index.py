#!/usr/bin/env python3
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

"""RM-first and incremental archive regressions; no cloud calls."""

import gzip
import hashlib
import sqlite3
from dataclasses import replace
from unittest.mock import patch

import pytest
import test_yarn_job_cost_api as fixtures
import yarn_job_cost_api as api
from test_yarn_job_cost_api import FakeEmrClient, FakeS3Client

PREFIX = "emr-logs/j-TEST/node/i-1/applications/"
KEY = PREFIX + "hadoop-yarn-resourcemanager-rm.log"


class VersionedS3(FakeS3Client):
    def __init__(self, objects):
        super().__init__(objects)
        self.reads = []
        self.prefixes = []
        self.conditional_reads = []

    def get_paginator(self, operation):
        assert operation == "list_objects_v2"
        return self

    def paginate(self, **kwargs):
        self.prefixes.append(kwargs["Prefix"])
        yield {
            "Contents": [
                {
                    "Key": key,
                    "Size": len(value),
                    "ETag": hashlib.sha256(value).hexdigest(),
                }
                for key, value in self.objects.items()
                if key.startswith(kwargs["Prefix"])
            ]
        }

    def get_object(self, **kwargs):
        key = kwargs["Key"]
        if "IfMatch" in kwargs:
            assert kwargs["IfMatch"] == hashlib.sha256(self.objects[key]).hexdigest()
        self.conditional_reads.append("IfMatch" in kwargs)
        self.reads.append(key)
        return super().get_object(**kwargs)


@pytest.fixture
def sample():
    case = fixtures.YarnJobCostApiTest()
    return (
        replace(case.request(), rm_only=True),
        case.yarn_log_with_instance_type().encode(),
    )


def calculate(request, s3, cache):
    return api.calculate_emr_application_usage(
        request, emr_client=FakeEmrClient(), s3_client=s3, cache_dir=cache
    )


def test_rm_only_skips_nm_and_reuses_index(tmp_path, sample):
    request, log = sample
    s3 = VersionedS3({KEY: log, PREFIX + "hadoop-yarn-nodemanager.log": b"unused"})
    first = calculate(request, s3, tmp_path)
    assert first.complete
    assert calculate(request, s3, tmp_path) == first
    assert s3.reads == [KEY]
    assert s3.conditional_reads == [True]
    assert not list(tmp_path.rglob("*.log"))


@pytest.mark.parametrize(
    "objects", [{}, {"fluentd/j-TEST/hadoop-yarn-resourcemanager.log": b""}]
)
def test_pending_shipper_does_not_fall_back_or_read_event_log(
    tmp_path, sample, objects
):
    request, log = sample
    request = replace(request, yarn_log_uri="s3://test-bucket/fluentd/j-TEST")
    s3 = VersionedS3({KEY: log, **objects})
    with patch.object(
        api,
        "read_event_log_metadata",
        side_effect=AssertionError("expensive event-log read"),
    ):
        result = calculate(request, s3, tmp_path)
    assert not result.complete and result.retryable
    assert s3.prefixes == ["fluentd/j-TEST/"]
    assert s3.reads == []


def test_missing_summary_is_pending_then_new_object_completes(tmp_path, sample):
    request, log = sample
    lines = log.splitlines(keepends=True)
    s3 = VersionedS3({KEY: b"".join(lines[:-1])})
    with patch.object(
        api,
        "read_event_log_metadata",
        side_effect=AssertionError("expensive event-log read"),
    ):
        pending = calculate(request, s3, tmp_path)
    assert not pending.complete and pending.retryable
    summary = PREFIX + "hadoop-yarn-resourcemanager-summary.log"
    s3.objects[summary] = lines[-1]
    assert calculate(request, s3, tmp_path).complete
    assert s3.reads == [KEY, summary]


def test_same_size_replacement_invalidates_and_deletion_removes_evidence(
    tmp_path, sample
):
    request, log = sample
    s3 = VersionedS3({KEY: log})
    first = calculate(request, s3, tmp_path)
    s3.objects[KEY] = log.replace(b"00:00:10,000", b"00:00:12,000")
    second = calculate(request, s3, tmp_path)
    assert second.complete
    assert second.vcore_seconds > first.vcore_seconds
    assert s3.reads == [KEY, KEY]
    s3.objects.clear()
    s3.objects[PREFIX + "hadoop-yarn-resourcemanager-startup.log"] = log.splitlines(
        keepends=True
    )[0]
    result = calculate(request, s3, tmp_path)
    assert not result.complete and result.retryable


def test_only_requested_application_is_accounted_with_historical_node_metadata(
    tmp_path, sample
):
    request, log = sample
    other = log.replace(b"application_1_0001", b"application_1_0002").replace(
        b"container_1_0001", b"container_1_0002"
    )
    lines = log.splitlines(keepends=True)
    s3 = VersionedS3(
        {
            KEY: b"".join(lines[2:]),
            PREFIX + "hadoop-yarn-resourcemanager-old.log": b"".join(lines[:2]) + other,
        }
    )
    with patch.object(
        api.reporting,
        "calculate_applications",
        wraps=api.reporting.calculate_applications,
    ) as report:
        indexed = calculate(request, s3, tmp_path)
    assert indexed.complete
    assert {c.application_id for c in report.call_args.args[0].containers.values()} == {
        request.application_id
    }
    assert indexed == calculate(replace(request, rm_only=False), s3, tmp_path)
    s3.reads.clear()
    second_request = replace(request, application_id="application_1_0002")
    # There is no matching Spark log for this app, but its YARN evidence is
    # already indexed: even a new application's lookup does not redownload it.
    assert not calculate(second_request, s3, tmp_path).complete
    assert not s3.reads


def test_failed_refresh_preserves_previous_object_and_resumes_cold_scan(
    tmp_path, sample
):
    request, log = sample
    second_key = PREFIX + "hadoop-yarn-resourcemanager-z.log"
    s3 = VersionedS3({KEY: log, second_key: log})
    original = s3.get_object

    def fail_second(**kwargs):
        if kwargs["Key"] == second_key:
            raise TimeoutError("download budget exhausted")
        return original(**kwargs)

    with patch.object(s3, "get_object", side_effect=fail_second):
        pending = calculate(request, s3, tmp_path)
    assert not pending.complete and pending.retryable
    assert calculate(request, s3, tmp_path).complete
    assert s3.reads == [KEY, second_key]


def test_sources_do_not_share_cached_evidence(tmp_path, sample):
    request, log = sample
    s3 = VersionedS3({KEY: log})
    assert calculate(request, s3, tmp_path).complete
    other_key = "shipper/hadoop-yarn-resourcemanager.log"
    s3.objects[other_key] = b"unrelated logs\n"
    other_request = replace(request, yarn_log_uri="s3://test-bucket/shipper/")
    assert not calculate(other_request, s3, tmp_path).complete
    assert len(list(tmp_path.glob("*.sqlite3"))) == 2


def test_expired_budget_is_retryable(tmp_path, sample):
    request, log = sample
    request = replace(request, timeout_seconds=1)
    s3 = VersionedS3({KEY: log})
    clock = iter([0, 2])
    with patch.object(api.time, "monotonic", side_effect=lambda: next(clock, 2)):
        result = calculate(request, s3, tmp_path)
    assert not result.complete and result.retryable
    assert not s3.reads


@pytest.mark.parametrize("timeout", [0, -1, float("nan"), float("inf")])
def test_invalid_budget_is_rejected(sample, timeout):
    with pytest.raises(ValueError, match="timeout_seconds"):
        replace(sample[0], timeout_seconds=timeout)


def test_truncated_replacement_rolls_back_and_recovers(tmp_path, sample):
    request, log = sample
    key = KEY + ".gz"
    s3 = VersionedS3({key: gzip.compress(log)})
    reference = calculate(request, s3, tmp_path)
    assert reference.complete
    database = next(tmp_path.glob("*.sqlite3"))
    with sqlite3.connect(database) as connection:
        previous = connection.execute("SELECT * FROM objects").fetchall()
    s3.objects[key] = gzip.compress(log.replace(b"00:00:10,000", b"00:00:12,000"))[:-5]
    pending = calculate(request, s3, tmp_path)
    assert not pending.complete and pending.retryable
    with sqlite3.connect(database) as connection:
        assert connection.execute("SELECT * FROM objects").fetchall() == previous
    s3.objects[key] = gzip.compress(log)
    assert calculate(request, s3, tmp_path) == reference


@pytest.mark.parametrize("code", ["PreconditionFailed", "NoSuchKey", "AccessDenied"])
def test_s3_snapshot_races_are_pending_but_auth_errors_propagate(
    tmp_path, sample, code
):
    class S3Error(Exception):
        response = {"Error": {"Code": code}}

    request, log = sample
    s3 = VersionedS3({KEY: log})
    with patch.object(s3, "get_object", side_effect=S3Error):
        if code == "AccessDenied":
            with pytest.raises(S3Error):
                calculate(request, s3, tmp_path)
        else:
            pending = calculate(request, s3, tmp_path)
            assert not pending.complete and pending.retryable
    assert calculate(request, s3, tmp_path).complete


def test_concurrent_writer_is_pending_and_releases_connection(tmp_path, sample):
    request, log = sample
    s3 = VersionedS3({KEY: log})
    reference = calculate(request, s3, tmp_path)
    with sqlite3.connect(next(tmp_path.glob("*.sqlite3"))) as writer:
        writer.execute("BEGIN IMMEDIATE")
        pending = calculate(request, s3, tmp_path)
        assert not pending.complete and pending.retryable
    assert calculate(request, s3, tmp_path) == reference


def test_malformed_persistent_index_is_not_reported_as_pending(tmp_path, sample):
    request, log = sample
    s3 = VersionedS3({KEY: log})
    assert calculate(request, s3, tmp_path).complete
    database = next(tmp_path.glob("*.sqlite3"))
    with sqlite3.connect(database) as connection:
        connection.execute("DROP TABLE records")
        connection.execute("CREATE TABLE records (bogus TEXT)")

    for _ in range(2):
        with pytest.raises(sqlite3.OperationalError, match="no such column: app"):
            calculate(request, s3, tmp_path)


def test_interrupted_sqlite_query_remains_retryable(tmp_path, sample):
    request, log = sample
    s3 = VersionedS3({KEY: log})
    with sqlite3.connect(":memory:") as connection:
        connection.set_progress_handler(lambda: 1, 1)
        with pytest.raises(sqlite3.OperationalError) as captured:
            connection.execute("SELECT 1")
    assert str(captured.value) == "interrupted"

    with patch.object(api, "materialize_application_logs", side_effect=captured.value):
        pending = calculate(request, s3, tmp_path)
    assert not pending.complete and pending.retryable


def test_concurrent_replacement_cannot_mix_snapshots(tmp_path, sample):
    request, log = sample
    key2 = PREFIX + "hadoop-yarn-resourcemanager-z.log"
    s3 = VersionedS3({KEY: log, key2: b"startup\n"})
    original = s3.get_object

    def competing_refresh(**kwargs):
        if kwargs["Key"] == key2:
            s3.objects[KEY] = log.replace(b"00:00:10,000", b"00:00:12,000")
            with patch.object(s3, "get_object", side_effect=original):
                assert calculate(request, s3, tmp_path).complete
        return original(**kwargs)

    with patch.object(s3, "get_object", side_effect=competing_refresh):
        pending = calculate(request, s3, tmp_path)
    assert not pending.complete and pending.retryable
    assert calculate(request, s3, tmp_path).complete


def test_older_listing_cannot_delete_newer_indexed_object(tmp_path, sample):
    request, log = sample
    new_key = PREFIX + "hadoop-yarn-resourcemanager-new.log"

    class ConcurrentUploadS3(VersionedS3):
        injected = False

        def paginate(self, **kwargs):
            snapshot = list(super().paginate(**kwargs))
            if not self.injected:
                self.injected = True
                self.objects[new_key] = b"unrelated activity\n"
                assert calculate(request, self, tmp_path).complete
            yield from snapshot

    s3 = ConcurrentUploadS3({KEY: log})
    pending = calculate(request, s3, tmp_path)
    assert not pending.complete and pending.retryable
    assert "RM index changed after listing" in pending.warnings[0]
    database = next(tmp_path.glob("*.sqlite3"))
    with sqlite3.connect(database) as connection:
        assert {row[0] for row in connection.execute("SELECT key FROM objects")} == {
            KEY,
            new_key,
        }
    assert calculate(request, s3, tmp_path).complete


@pytest.mark.parametrize("history_size", [1, 200])
def test_warm_work_does_not_parse_historical_applications(
    tmp_path, sample, history_size
):
    request, log = sample
    objects = {KEY: log}
    for app in range(2, history_size + 2):
        objects[PREFIX + f"hadoop-yarn-resourcemanager-{app:04d}.log"] = log.replace(
            b"application_1_0001", f"application_1_{app:04d}".encode()
        ).replace(b"container_1_0001", f"container_1_{app:04d}".encode())
    s3 = VersionedS3(objects)
    cold = calculate(request, s3, tmp_path)
    assert cold.complete
    assert len(s3.reads) == history_size + 1
    s3.reads.clear()
    with patch.object(api, "parse_yarn_logs", wraps=api.parse_yarn_logs) as parser:
        assert calculate(request, s3, tmp_path) == cold
        assert parser.call_count == 1
    assert s3.reads == []
