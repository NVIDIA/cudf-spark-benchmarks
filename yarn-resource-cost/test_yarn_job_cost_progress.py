#!/usr/bin/env python3
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

"""Deterministic progress regressions: simulated time, no AWS or sleeps."""

import io
import tarfile
from dataclasses import replace
from unittest.mock import patch

import pytest
import test_yarn_job_cost_api as fixtures
import yarn_job_cost_api as api
import yarn_job_cost_discovery as discovery
from test_yarn_job_cost_index import KEY, VersionedS3, calculate


class DelayedS3(VersionedS3):
    def __init__(self, objects, clock, delay):
        super().__init__(objects)
        self.clock = clock
        self.delay = delay

    def get_object(self, **kwargs):
        response = super().get_object(**kwargs)
        original = response["Body"].read

        def read(*args):
            chunk = original(*args)
            if chunk:
                self.clock[0] += self.delay(kwargs["Key"])
            return chunk

        response["Body"].read = read
        return response


def event_fixture():
    case = fixtures.YarnJobCostApiTest()
    prefix = "events/eventlog_v2_application_1_0001"
    request = replace(
        case.request(), rm_only=True, event_log_uri=f"s3://test-bucket/{prefix}"
    )
    lines = (
        (
            fixtures.FIXTURE
            / "eventlog_v2_application_1_0001/events_1_application_1_0001"
        )
        .read_bytes()
        .splitlines(keepends=True)
    )
    objects = {KEY: case.yarn_log_with_instance_type().encode()}
    for number, (start, end) in enumerate(((0, 2), (2, 4), (4, len(lines))), 1):
        objects[f"{prefix}/events_{number}_application_1_0001"] = b"".join(
            lines[start:end]
        )
    return request, objects


def test_event_downloads_resume_with_same_budget(tmp_path):
    request, objects = event_fixture()
    clock = [0]
    s3 = DelayedS3(objects, clock, lambda key: 50 if key.startswith("events/") else 0)
    with patch.object(api.time, "monotonic", side_effect=lambda: clock[0]):
        assert calculate(request, s3, tmp_path).retryable
        assert calculate(request, s3, tmp_path).complete
        reads = len(s3.reads)
        warm = calculate(request, s3, tmp_path)
        assert warm.complete and len(s3.reads) == reads
    assert warm == calculate(
        replace(request, rm_only=False), VersionedS3(objects), None
    )
    # Only the interrupted third segment is downloaded twice.
    assert len(s3.reads) == 5


def test_event_parsing_resumes_across_segments(tmp_path):
    request, objects = event_fixture()
    clock = [0]
    s3 = VersionedS3(objects)
    original = discovery._iter_application_event_lines
    parsed = []

    def slow_parse(stream, codec, member, application):
        parsed.append(member)
        clock[0] += 50
        yield from original(stream, codec, member, application)

    with patch.object(
        api.time, "monotonic", side_effect=lambda: clock[0]
    ), patch.object(discovery, "_iter_application_event_lines", slow_parse):
        assert calculate(request, s3, tmp_path).retryable
        result = calculate(request, s3, tmp_path)
        assert result.complete
        assert len(parsed) == 4  # two checkpoints reused, only segment three resumes
    assert result == calculate(
        replace(request, rm_only=False), VersionedS3(objects), None
    )


def test_new_rm_objects_progress_ahead_of_changing_active_log(tmp_path):
    case = fixtures.YarnJobCostApiTest()
    request = replace(case.request(), rm_only=True)
    rolled = KEY + ".2026-09-29"
    clock = [0]
    s3 = DelayedS3(
        {KEY: b"active 0\n", rolled: case.yarn_log_with_instance_type().encode()},
        clock,
        lambda key: 70,
    )
    with patch.object(api.time, "monotonic", side_effect=lambda: clock[0]):
        for attempt in range(3):
            s3.objects[KEY] = f"active {attempt}\n".encode()
            result = calculate(request, s3, tmp_path)
            assert result.complete == (attempt == 2)
    assert s3.reads == [KEY, rolled, rolled, KEY, KEY]


@pytest.mark.parametrize("slow_stage", ["download", "parse"])
def test_event_progress_is_not_starved_by_recurring_rm_work(tmp_path, slow_stage):
    request, objects = event_fixture()
    rm_body = objects[KEY]
    clock = [0]
    s3 = DelayedS3(
        objects,
        clock,
        lambda key: 70 if key == KEY else (60 if slow_stage == "download" else 0),
    )
    original = discovery._iter_application_event_lines

    def parse(stream, codec, member, application):
        if slow_stage == "parse":
            clock[0] += 60
        yield from original(stream, codec, member, application)

    with patch.object(
        api.time, "monotonic", side_effect=lambda: clock[0]
    ), patch.object(discovery, "_iter_application_event_lines", parse):
        for attempt in range(8):
            # Other applications keep the RM source changing after ours ends.
            s3.objects[KEY] = rm_body + f"unrelated activity {attempt}\n".encode()
            result = calculate(request, s3, tmp_path)
            if result.complete:
                break
            assert result.retryable
        assert result.complete
    assert result == calculate(
        replace(request, rm_only=False), VersionedS3(objects), None
    )


def test_event_priority_does_not_make_old_rm_evidence_authoritative(tmp_path):
    request, objects = event_fixture()
    s3 = VersionedS3(objects)
    assert calculate(request, s3, tmp_path).complete
    # The scheduling hint survives a replacement that removes the summary.
    s3.objects[KEY] = b"".join(objects[KEY].splitlines(keepends=True)[:-1])
    result = calculate(request, s3, tmp_path)
    assert not result.complete and result.retryable
    assert result.warnings == ("ResourceManager ApplicationSummary is missing",)
    # Even a warm hint cannot bypass the cheap no-RM gate.
    del s3.objects[KEY]
    with patch.object(
        api, "_read_application_metadata", side_effect=AssertionError("event read")
    ):
        result = calculate(request, s3, tmp_path)
    assert not result.complete and result.retryable


@pytest.mark.parametrize(
    "changed", ["application_id", "event_log_uri", "yarn_log_uri", "cluster_id"]
)
def test_event_priority_is_scoped_to_source_and_application(tmp_path, changed):
    request, objects = event_fixture()
    s3 = VersionedS3(objects)
    assert calculate(request, s3, tmp_path).complete
    s3.objects[KEY] = b"no summary\n"
    values = {
        "application_id": "application_1_9999",
        "event_log_uri": request.event_log_uri + "-other",
        "yarn_log_uri": "s3://test-bucket/other/",
        "cluster_id": "j-OTHER",
    }
    s3.objects["other/hadoop-yarn-resourcemanager.log"] = b"no summary\n"
    with patch.object(
        api, "_read_application_metadata", side_effect=AssertionError("event read")
    ):
        result = calculate(replace(request, **{changed: values[changed]}), s3, tmp_path)
    assert not result.complete and result.retryable


def test_event_replacement_invalidates_successor_checkpoints(tmp_path):
    request, objects = event_fixture()
    s3 = VersionedS3(objects)
    assert calculate(request, s3, tmp_path).complete
    first = next(key for key in objects if "/events_2_" in key)
    s3.objects[first] = s3.objects[first].replace(
        b"application_1_0001", b"application_1_0099"
    )
    result = calculate(request, s3, tmp_path)
    assert not result.complete and result.retryable
    assert result == calculate(replace(request, rm_only=False), s3, None)


def test_failed_event_download_never_publishes_partial_blob(tmp_path):
    request, objects = event_fixture()
    s3 = VersionedS3(objects)
    original = s3.get_object

    class BrokenBody(io.BytesIO):
        def read(self, *args):
            if self.tell():
                raise TimeoutError("interrupted")
            return super().read(1)

    def download(**kwargs):
        if kwargs["Key"].startswith("events/"):
            return {"Body": BrokenBody(objects[kwargs["Key"]])}
        return original(**kwargs)

    with patch.object(s3, "get_object", side_effect=download):
        assert calculate(request, s3, tmp_path).retryable
    assert not list((tmp_path / "event-objects-v1").iterdir())
    assert calculate(request, s3, tmp_path).complete


def test_local_event_parsing_uses_segment_checkpoints(tmp_path):
    request, objects = event_fixture()
    local = tmp_path / "eventlog_v2_application_1_0001"
    local.mkdir()
    for key, body in objects.items():
        if key.startswith("events/"):
            (local / key.rsplit("/", 1)[-1]).write_bytes(body)
    request = replace(request, event_log_uri=str(local))
    s3 = VersionedS3({KEY: objects[KEY]})
    reference = calculate(request, s3, tmp_path / "cache")
    with patch.object(
        discovery,
        "_iter_application_event_lines",
        side_effect=AssertionError("warm parser"),
    ):
        assert calculate(request, s3, tmp_path / "cache") == reference
    assert reference.complete


def test_deleted_segment_does_not_reuse_stale_metadata(tmp_path):
    request, objects = event_fixture()
    s3 = VersionedS3(objects)
    assert calculate(request, s3, tmp_path).complete
    del s3.objects[next(key for key in objects if "/events_2_" in key)]
    with patch.object(
        discovery,
        "_iter_application_event_lines",
        wraps=discovery._iter_application_event_lines,
    ) as parse:
        result = calculate(request, s3, tmp_path)
        assert parse.call_count == 1  # the surviving successor must be replayed
    assert result == calculate(replace(request, rm_only=False), s3, None)


def test_corrupt_checkpoint_is_reparsed_not_executed(tmp_path):
    request, objects = event_fixture()
    s3 = VersionedS3(objects)
    reference = calculate(request, s3, tmp_path)
    for checkpoint in (tmp_path / "event-metadata-v1").glob("*.json"):
        checkpoint.write_text("broken JSON", encoding="utf-8")
    assert calculate(request, s3, tmp_path) == reference


def test_unreadable_segment_and_successors_are_not_checkpointed(tmp_path):
    request, objects = event_fixture()
    key = next(key for key in objects if "/events_2_" in key)
    objects[key + ".lz4"] = b"truncated"
    del objects[key]
    s3 = VersionedS3(objects)
    result = calculate(request, s3, tmp_path)
    assert not result.complete and result.retryable
    assert len(list((tmp_path / "event-metadata-v1").glob("*.json"))) == 1
    del s3.objects[key + ".lz4"]
    s3.objects[key] = event_fixture()[1][key]
    assert calculate(request, s3, tmp_path).complete


def test_local_tar_uses_successful_member_checkpoints(tmp_path):
    request, objects = event_fixture()
    archive = tmp_path / "events.tar.gz"
    with tarfile.open(archive, "w:gz") as output:
        for key, body in objects.items():
            if key.startswith("events/"):
                member = tarfile.TarInfo(key.removeprefix("events/"))
                member.size = len(body)
                output.addfile(member, io.BytesIO(body))
    request = replace(request, event_log_uri=str(archive))
    s3 = VersionedS3({KEY: objects[KEY]})
    reference = calculate(request, s3, tmp_path / "cache")
    assert reference.complete
    with patch.object(
        discovery,
        "_iter_application_event_lines",
        side_effect=AssertionError("warm tar parser"),
    ):
        assert calculate(request, s3, tmp_path / "cache") == reference
