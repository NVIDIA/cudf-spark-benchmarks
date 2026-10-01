#!/usr/bin/env python3
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

"""Typed library API for application-scoped YARN resource accounting."""

from __future__ import annotations

import hashlib
import json
import logging
import math
import sqlite3
import tempfile
import time
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Iterable
from urllib.parse import urlparse
from urllib.request import url2pathname

import calculate_yarn_job_cost as reporting
from yarn_job_cost_checkpoint import EventCheckpoints
from yarn_job_cost_core import calculator_mode, parse_yarn_logs
from yarn_job_cost_discovery import read_event_log_metadata
from yarn_job_cost_index import (
    ArchivePendingError,
    materialize_application_logs,
    read_index_generation,
)

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class EmrApplicationUsageRequest:
    """Inputs needed to attribute one EMR YARN application."""

    cluster_id: str
    application_id: str
    event_log_uri: str
    region: str
    include_application_master: bool = False
    yarn_log_uri: str | None = None
    """Optional S3 prefix holding this cluster's ResourceManager logs.

    Use this when a log shipper uploads ResourceManager logs faster than the EMR
    log pusher. When it contains no ResourceManager logs, the cluster LogUri
    archive is used instead unless rm_only is enabled.
    """
    rm_only: bool = False
    timeout_seconds: float | None = None

    def __post_init__(self) -> None:
        for name in ("cluster_id", "application_id", "event_log_uri", "region"):
            if not getattr(self, name).strip():
                raise ValueError(f"{name} is required")
        if self.yarn_log_uri is not None:
            _split_s3_uri(self.yarn_log_uri)
        if self.timeout_seconds is not None and (
            not math.isfinite(self.timeout_seconds) or self.timeout_seconds <= 0
        ):
            raise ValueError("timeout_seconds must be finite and positive")


@dataclass(frozen=True)
class YarnApplicationUsageResult:
    """Resource usage and evidence for one YARN application."""

    application_id: str
    complete: bool
    retryable: bool
    resource_calculator: str = ""
    detected_resource_calculator_class: str = ""
    vcore_seconds: float | None = None
    memory_mb_seconds: float | None = None
    instance_seconds_by_type: dict[str, float] = field(default_factory=dict)
    container_count: int = 0
    expected_container_count: int | None = None
    incomplete_container_count: int = 0
    warnings: tuple[str, ...] = ()

    def as_dict(self) -> dict[str, Any]:
        """Return a JSON-safe representation."""

        return asdict(self)


def _split_s3_uri(uri: str) -> tuple[str, str]:
    if not uri.startswith(("s3://", "s3a://", "s3n://")):
        raise ValueError(f"Expected an S3 URI, got {uri}")
    bucket_and_key = uri.split("://", 1)[1]
    bucket, separator, key = bucket_and_key.partition("/")
    if not bucket:
        raise ValueError(f"S3 URI has no bucket: {uri}")
    return bucket, key if separator else ""


def _list_s3_objects(
    s3_client: Any, bucket: str, prefix: str
) -> Iterable[dict[str, Any]]:
    started = time.monotonic()
    count = 0
    paginator = s3_client.get_paginator("list_objects_v2")
    try:
        for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
            items = page.get("Contents") or ()
            count += len(items)
            yield from items
    finally:
        logger.info(
            "event=yarn_archive_list objects=%d duration_seconds=%.3f",
            count,
            time.monotonic() - started,
        )


def _safe_relative_key(key: str, prefix: str) -> Path:
    relative = key[len(prefix) :].lstrip("/") if key.startswith(prefix) else key
    parts = [part for part in Path(relative).parts if part not in ("", ".", "..")]
    if not parts:
        parts = [Path(key).name or "download"]
    return Path(*parts)


def _list_rm_objects(s3_client, bucket, prefix, check_budget, *, first_only=False):
    check_budget()
    candidates = []
    for item in _list_s3_objects(s3_client, bucket, prefix):
        check_budget()
        if (
            item.get("Size") != 0
            and "hadoop-yarn-resourcemanager" in Path(item["Key"]).name
        ):
            candidates.append(item)
            if first_only:
                break
    return candidates


def _download_objects(
    s3_client: Any,
    bucket: str,
    prefix: str,
    objects: Iterable[dict[str, Any]],
    destination: Path,
    check_budget=lambda: None,
    cache_dir: Path | None = None,
) -> list[Path]:
    started = time.monotonic()
    transferred = 0
    reused = 0
    downloaded = []
    for item in objects:
        check_budget()
        key = str(item.get("Key") or "")
        if not key or key.endswith("/"):
            continue
        target = destination / _safe_relative_key(key, prefix)
        target.parent.mkdir(parents=True, exist_ok=True)
        blob = None
        if cache_dir is not None and item.get("ETag"):
            identity = json.dumps(
                [
                    bucket,
                    key,
                    item["ETag"],
                    item.get("Size"),
                    str(item.get("LastModified", "")),
                ]
            )
            blob_dir = cache_dir / "event-objects-v1"
            blob_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
            blob = blob_dir / hashlib.sha256(identity.encode()).hexdigest()
            if blob.is_file() and (
                item.get("Size") is None or blob.stat().st_size == item["Size"]
            ):
                target.symlink_to(blob.resolve())
                downloaded.append(target)
                reused += 1
                continue
        condition = {"IfMatch": item["ETag"]} if item.get("ETag") else {}
        try:
            body = s3_client.get_object(Bucket=bucket, Key=key, **condition)["Body"]
        except Exception as error:
            # Keep boto3 optional: only recognize the documented S3 race codes;
            # authentication and other transport/provider failures still escape.
            response = getattr(error, "response", {})
            code = (
                response.get("Error", {}).get("Code")
                if isinstance(response, dict)
                else None
            )
            if code in {"PreconditionFailed", "NoSuchKey", "412", "404"}:
                raise ArchivePendingError(
                    "Archive changed after listing; retry this snapshot"
                ) from error
            raise
        temporary = None
        try:
            if blob is not None:
                # Publish complete objects independently of metadata parsing.
                # Temporary files live beside the blob for atomic replacement.
                output = tempfile.NamedTemporaryFile(dir=blob.parent, delete=False)
                temporary = Path(output.name)
            else:
                output = target.open("wb")
            written = 0
            with output:
                while chunk := body.read(1024 * 1024):
                    check_budget()
                    output.write(chunk)
                    written += len(chunk)
                    transferred += len(chunk)
            if item.get("Size") is not None and written != item["Size"]:
                raise ArchivePendingError(
                    "Archive download length differs from the listed object; retry this snapshot"
                )
            if blob is not None:
                temporary.replace(blob)
                target.symlink_to(blob.resolve())
        finally:
            close = getattr(body, "close", None)
            if close:
                close()
            if temporary is not None:
                temporary.unlink(missing_ok=True)
        downloaded.append(target)
    logger.info(
        "event=yarn_archive_download objects=%d reused=%d bytes=%d duration_seconds=%.3f",
        len(downloaded) - reused,
        reused,
        transferred,
        time.monotonic() - started,
    )
    return downloaded


def _materialize_event_log(
    s3_client: Any,
    uri: str,
    destination: Path,
    check_budget=lambda: None,
    cache_dir: Path | None = None,
) -> Path:
    if not uri.startswith(("s3://", "s3a://", "s3n://")):
        if uri.lower().startswith("file:"):
            parsed = urlparse(uri)
            if parsed.netloc and parsed.netloc.lower() != "localhost":
                raise ValueError(f"File URI has a remote authority: {uri}")
            if not parsed.path or parsed.query or parsed.fragment:
                raise ValueError(f"Invalid file URI: {uri}")
            path = Path(url2pathname(parsed.path)).expanduser()
        else:
            path = Path(uri).expanduser()
        if not path.exists():
            raise ValueError(f"Event log does not exist: {uri}")
        return path

    bucket, key = _split_s3_uri(uri)
    prefix = key.rstrip("/")
    objects = []
    for item in _list_s3_objects(s3_client, bucket, prefix):
        check_budget()
        objects.append(item)
    exact_object = next(
        (
            item
            for item in objects
            if str(item.get("Key") or "") == key and not key.endswith("/")
        ),
        None,
    )
    if exact_object is not None:
        downloaded = _download_objects(
            s3_client,
            bucket,
            prefix,
            (exact_object,),
            destination,
            check_budget,
            cache_dir,
        )
        return downloaded[0] if downloaded else destination
    selected = [
        item
        for item in objects
        if Path(str(item.get("Key") or "")).name.startswith("events_")
        or str(item.get("Key") or "") == key
    ]
    if not selected:
        return destination
    prefix_name = Path(prefix).name
    event_destination = (
        destination / prefix_name
        if prefix_name.startswith("eventlog_")
        else destination
    )
    _download_objects(
        s3_client, bucket, prefix, selected, event_destination, check_budget, cache_dir
    )
    return destination


def _cluster_log_uri(emr_client: Any, cluster_id: str) -> str:
    cluster = emr_client.describe_cluster(ClusterId=cluster_id).get("Cluster") or {}
    log_uri = str(cluster.get("LogUri") or "").strip()
    if not log_uri:
        raise ValueError(f"EMR cluster {cluster_id} has no LogUri")
    _scheme, separator, bucket_and_key = log_uri.partition("://")
    if not separator or not bucket_and_key:
        raise ValueError(f"EMR cluster {cluster_id} has an invalid LogUri")
    normalized = "s3://" + bucket_and_key
    if normalized.rstrip("/").endswith("/" + cluster_id):
        return normalized.rstrip("/") + "/"
    return normalized.rstrip("/") + f"/{cluster_id}/"


def _download_yarn_logs(
    s3_client: Any,
    log_uri: str,
    markers: tuple[str, ...],
    destination: Path,
    check_budget=lambda: None,
) -> list[Path]:
    bucket, prefix = _split_s3_uri(log_uri)
    if prefix and not prefix.endswith("/"):
        # Directory boundary: "j-TEST" must not also match "j-TEST2/".
        prefix += "/"
    objects = []
    for item in _list_s3_objects(s3_client, bucket, prefix):
        check_budget()
        if item.get("Size") != 0 and any(
            marker in Path(str(item.get("Key") or "")).name for marker in markers
        ):
            objects.append(item)
    check_budget()
    return _download_objects(
        s3_client, bucket, prefix, objects, destination, check_budget
    )


def _materialize_yarn_logs(
    emr_client: Any,
    s3_client: Any,
    cluster_id: str,
    destination: Path,
    yarn_log_uri: str | None = None,
    check_budget=lambda: None,
) -> list[Path]:
    if yarn_log_uri:
        downloaded = _download_yarn_logs(
            s3_client,
            yarn_log_uri,
            ("hadoop-yarn-resourcemanager",),
            destination,
            check_budget,
        )
        if downloaded:
            return downloaded
    return _download_yarn_logs(
        s3_client,
        _cluster_log_uri(emr_client, cluster_id),
        ("hadoop-yarn-resourcemanager", "hadoop-yarn-nodemanager"),
        destination,
        check_budget,
    )


def _empty_result(
    request: EmrApplicationUsageRequest,
    warning: str,
    *,
    retryable: bool,
    detected_calculator: str = "",
) -> YarnApplicationUsageResult:
    return YarnApplicationUsageResult(
        application_id=request.application_id,
        complete=False,
        retryable=retryable,
        detected_resource_calculator_class=detected_calculator,
        warnings=(warning,),
    )


def calculate_emr_application_usage(
    request: EmrApplicationUsageRequest,
    *,
    emr_client: Any,
    s3_client: Any,
    cache_dir: Path | str | None = None,
) -> YarnApplicationUsageResult:
    """Calculate YARN resource usage for one EMR application.

    Missing or not-yet-complete archived logs are returned as retryable incomplete
    results. Provider authentication and transport errors are allowed to propagate.
    """

    budget = request.timeout_seconds
    if budget is None and request.rm_only:
        budget = 120.0
    deadline = time.monotonic() + budget if budget is not None else None

    def check_budget():
        if deadline is not None and time.monotonic() >= deadline:
            raise TimeoutError("YARN accounting attempt exceeded its time budget")

    try:
        check_budget()
        return _calculate_emr_application_usage(
            request, emr_client, s3_client, cache_dir, check_budget
        )
    except (TimeoutError, sqlite3.OperationalError, ArchivePendingError) as error:
        if isinstance(error, sqlite3.OperationalError):
            code = getattr(error, "sqlite_errorcode", None)
            # SQLite also reports a budget-interrupted progress callback as an
            # OperationalError. Lock contention is likewise safe to retry, but
            # storage or schema failures will not be fixed by waiting for logs.
            if not isinstance(code, int) or code & 0xFF not in {
                sqlite3.SQLITE_BUSY,
                sqlite3.SQLITE_LOCKED,
                sqlite3.SQLITE_INTERRUPT,
            }:
                raise
        logger.info("event=yarn_accounting_pending reason=%s", type(error).__name__)
        return _empty_result(request, str(error), retryable=True)


def _calculate_emr_application_usage(
    request, emr_client, s3_client, cache_dir, check_budget
):
    with tempfile.TemporaryDirectory(prefix="yarn-resource-cost-") as directory:
        root = Path(directory)
        event_cache = Path(cache_dir) if cache_dir is not None else None
        metadata = None
        event_priority = None
        if not request.rm_only:
            metadata = _read_application_metadata(
                request, s3_client, root, check_budget, event_cache
            )
            if isinstance(metadata, YarnApplicationUsageResult):
                return metadata
        # Check RM availability before reading a potentially large Spark log.
        yarn_root = root / "yarn"
        if request.rm_only:
            log_uri = request.yarn_log_uri or _cluster_log_uri(
                emr_client, request.cluster_id
            )
            bucket, prefix = _split_s3_uri(log_uri)
            prefix = prefix.rstrip("/") + "/" if prefix else ""
            index_cache = Path(cache_dir) if cache_dir is not None else root / "index"
            if event_cache is not None:
                identity = json.dumps(
                    [
                        bucket,
                        prefix,
                        request.cluster_id,
                        request.application_id,
                        request.event_log_uri,
                        request.region,
                    ]
                )
                event_priority = (
                    event_cache
                    / "event-priority-v1"
                    / hashlib.sha256(identity.encode()).hexdigest()
                )
            prioritize_events = event_priority is not None and event_priority.is_file()
            listing_generation = (
                read_index_generation(index_cache, bucket, prefix)
                if not prioritize_events
                else None
            )
            candidates = _list_rm_objects(
                s3_client, bucket, prefix, check_budget, first_only=prioritize_events
            )
            if not candidates:
                # An explicitly configured shipper is authoritative. Falling
                # back while it is still uploading defeats cheap pending checks.
                return _empty_result(
                    request, "No archived ResourceManager logs found", retryable=True
                )
            if prioritize_events:
                # Once an earlier attempt observed the target summary, give
                # event checkpoints the first processing slice. Otherwise a
                # changing RM log can consume that slice on every retry.
                metadata = _read_application_metadata(
                    request, s3_client, root, check_budget, event_cache
                )
                if isinstance(metadata, YarnApplicationUsageResult):
                    return metadata
                # The initial probe stops at the first RM object. Event work can
                # outlast its upload interval, even with warm checkpoints; list
                # the full current snapshot only now, just before indexing.
                listing_generation = read_index_generation(index_cache, bucket, prefix)
                candidates = _list_rm_objects(s3_client, bucket, prefix, check_budget)
                if not candidates:
                    return _empty_result(
                        request,
                        "No archived ResourceManager logs found",
                        retryable=True,
                    )

            def download(item):
                return _download_objects(
                    s3_client, bucket, prefix, [item], root / "downloads", check_budget
                )[0]

            started = time.monotonic()
            yarn_root, changed = materialize_application_logs(
                bucket=bucket,
                prefix=prefix,
                objects=candidates,
                application_id=request.application_id,
                cache_dir=index_cache,
                destination=yarn_root / "hadoop-yarn-resourcemanager-index.log",
                download=download,
                check_budget=check_budget,
                listing_generation=listing_generation,
            )
            logger.info(
                "event=yarn_rm_index objects=%d changed=%d reused=%d duration_seconds=%.3f",
                len(candidates),
                changed,
                len(candidates) - changed,
                time.monotonic() - started,
            )
        else:
            downloaded = _materialize_yarn_logs(
                emr_client,
                s3_client,
                request.cluster_id,
                yarn_root,
                request.yarn_log_uri,
                check_budget,
            )
            if not downloaded:
                return _empty_result(
                    request,
                    "No archived ResourceManager or NodeManager logs found",
                    retryable=True,
                )
        try:
            started = time.monotonic()
            evidence = parse_yarn_logs(yarn_root, check_budget=check_budget)
            logger.info(
                "event=yarn_application_parse containers=%d duration_seconds=%.3f",
                len(evidence.containers),
                time.monotonic() - started,
            )
        except ValueError as error:
            return _empty_result(request, str(error), retryable=False)
        if (
            request.rm_only
            and request.application_id not in evidence.application_summaries
        ):
            return _empty_result(
                request, "ResourceManager ApplicationSummary is missing", retryable=True
            )

        if metadata is None:
            if event_priority is not None:
                # Scheduling hint only: every successful attempt still refreshes
                # RM evidence and checks its summary above. No cached evidence
                # is made authoritative by this marker, even if it becomes stale.
                event_priority.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
                event_priority.touch(mode=0o600, exist_ok=True)
            metadata = _read_application_metadata(
                request, s3_client, root, check_budget, event_cache
            )
            if isinstance(metadata, YarnApplicationUsageResult):
                return metadata

        try:
            mode = calculator_mode(evidence.calculator_class)
        except ValueError as error:
            return _empty_result(
                request,
                str(error),
                retryable=not bool(evidence.calculator_class),
                detected_calculator=evidence.calculator_class,
            )

        executor_containers = {
            executor.container_id
            for executor in metadata.executors.values()
            if executor.container_id
        }
        evidence.containers = {
            key: value
            for key, value in evidence.containers.items()
            if value.application_id == request.application_id
        }
        applications = reporting.calculate_applications(
            evidence,
            mode,
            {request.application_id: metadata.as_metadata()},
            request.include_application_master,
            executor_containers,
        )
        check_budget()
        application = next(
            (
                item
                for item in applications
                if item["application_id"] == request.application_id
            ),
            None,
        )
        if application is None:
            return _empty_result(
                request,
                f"Application {request.application_id} is missing from archived YARN logs",
                retryable=True,
                detected_calculator=evidence.calculator_class,
            )

        expected = application.get("expected_total_allocated_containers")
        return YarnApplicationUsageResult(
            application_id=request.application_id,
            complete=bool(application["complete"]),
            retryable=bool(application["retryable"]),
            resource_calculator=mode,
            detected_resource_calculator_class=evidence.calculator_class,
            vcore_seconds=float(application["vcore_seconds"]),
            memory_mb_seconds=float(application["memory_mb_seconds"]),
            instance_seconds_by_type={
                str(instance_type): float(seconds)
                for instance_type, seconds in application[
                    "node_equivalent_seconds_by_instance_type"
                ].items()
            },
            container_count=int(application["container_count"]),
            expected_container_count=int(expected) if expected != "" else None,
            incomplete_container_count=int(application["incomplete_container_count"]),
            warnings=tuple(str(warning) for warning in application["warnings"]),
        )


def _read_application_metadata(request, s3_client, root, check_budget, cache_dir=None):
    started = time.monotonic()
    event_root = _materialize_event_log(
        s3_client, request.event_log_uri, root / "events", check_budget, cache_dir
    )
    logger.info(
        "event=yarn_eventlog_materialize duration_seconds=%.3f",
        time.monotonic() - started,
    )
    started = time.monotonic()
    checkpoints = (
        EventCheckpoints(cache_dir, request.event_log_uri)
        if cache_dir is not None
        else None
    )
    metadata = read_event_log_metadata(
        event_root, check_budget=check_budget, checkpoints=checkpoints
    ).get(request.application_id)
    logger.info(
        "event=yarn_eventlog_parse checkpoint_hits=%d duration_seconds=%.3f",
        checkpoints.hits if checkpoints else 0,
        time.monotonic() - started,
    )
    if metadata is None:
        return _empty_result(
            request,
            f"Application {request.application_id} is missing from the Spark event log",
            retryable=True,
        )
    if metadata.event_log_read_errors:
        return _empty_result(
            request,
            " | ".join(metadata.event_log_read_errors),
            retryable=metadata.event_log_read_retryable,
        )
    return metadata


__all__ = [
    "EmrApplicationUsageRequest",
    "YarnApplicationUsageResult",
    "calculate_emr_application_usage",
]
