#!/usr/bin/env python3
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

"""Disposable, versioned RM archive index for application-scoped accounting."""

from __future__ import annotations

import gzip
import hashlib
import json
import sqlite3
import uuid
import zlib
from contextlib import closing
from pathlib import Path
from typing import Callable

from yarn_job_cost_core import (
    APPLICATION_SUMMARY_RE,
    CALCULATOR_RE,
    CONTAINER_PARTS_RE,
    FAIR_POLICY_RE,
    RM_NODE_RE,
    normalize_log_line,
    open_log,
)


class ArchivePendingError(Exception):
    """An archive snapshot is changing or not yet readable in full."""


def _database_path(cache_dir: Path, bucket: str, prefix: str) -> Path:
    identity = hashlib.sha256(f"{bucket}/{prefix}".encode()).hexdigest()
    return cache_dir / f"rm-index-v1-{identity}.sqlite3"


def read_index_generation(cache_dir: Path, bucket: str, prefix: str) -> int:
    """Fence an S3 listing against later writes to this source's index."""
    database = _database_path(cache_dir, bucket, prefix)
    if not database.exists():
        return 0
    with closing(sqlite3.connect(database, timeout=1)) as connection:
        try:
            row = connection.execute(
                "SELECT generation FROM index_state WHERE singleton = 1"
            ).fetchone()
        except sqlite3.OperationalError as error:
            if "no such table" not in str(error):
                raise
            # An index created before the generation fence has no state row.
            return 0
    return row[0] if row else 0


def _application(line: str) -> str | None:
    # Cluster-wide metadata must remain available even when the registration or
    # scheduler startup predates the application by weeks.
    if (
        RM_NODE_RE.search(line)
        or CALCULATOR_RE.search(line)
        or FAIR_POLICY_RE.search(line)
    ):
        return ""
    match = APPLICATION_SUMMARY_RE.search(line)
    if match:
        return match.group("application")
    match = CONTAINER_PARTS_RE.search(line)
    if match:
        return f"application_{match.group('cluster')}_{match.group('application')}"
    return None


def materialize_application_logs(
    *,
    bucket: str,
    prefix: str,
    objects: list[dict],
    application_id: str,
    cache_dir: Path,
    destination: Path,
    download: Callable[[dict], Path],
    check_timeout: Callable[[], None],
    listing_generation: int,
) -> tuple[Path, int]:
    """Refresh changed objects atomically and emit only this app plus global evidence.

    The database contains normalized log lines, never executable serialized
    Python objects. A schema-versioned filename makes this a disposable cache.
    ETags are opaque object identities, not assumed to be content hashes.
    """
    cache_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    database = _database_path(cache_dir, bucket, prefix)
    # The index contains raw log evidence. Create it privately before SQLite
    # opens it; do not change the permissions of a caller-owned directory.
    database.touch(mode=0o600, exist_ok=True)
    changed = 0
    with closing(sqlite3.connect(database, timeout=1)) as connection:
        # This is a rebuildable cache, not the durable accounting store. WAL
        # with NORMAL sync preserves atomicity without fsyncing every object.
        # A host power loss may discard recent commits; those objects are then
        # fetched again, never considered indexed without their records.
        connection.execute("PRAGMA journal_mode=WAL")
        connection.execute("PRAGMA synchronous=NORMAL")
        # SQLite converts callback exceptions into OperationalError, which the
        # API returns as pending. Include large selections/deletions in budget.
        connection.set_progress_handler(lambda: check_timeout() or 0, 10000)
        connection.executescript(
            "CREATE TABLE IF NOT EXISTS objects (key TEXT PRIMARY KEY, fingerprint TEXT);"
            "CREATE TABLE IF NOT EXISTS records (key TEXT, line INTEGER, app TEXT, text TEXT);"
            "CREATE INDEX IF NOT EXISTS records_app ON records(app, key, line);"
            "CREATE INDEX IF NOT EXISTS records_key ON records(key);"
            "CREATE TABLE IF NOT EXISTS index_state "
            "(singleton INTEGER PRIMARY KEY CHECK (singleton = 1), generation INTEGER NOT NULL);"
            "INSERT OR IGNORE INTO index_state VALUES (1, 0);"
        )
        generation = listing_generation
        if connection.execute(
            "SELECT generation FROM index_state WHERE singleton = 1"
        ).fetchone() != (generation,):
            raise ArchivePendingError(
                "RM index changed after listing; retry this snapshot"
            )
        expected = {}
        known = dict(connection.execute("SELECT key, fingerprint FROM objects"))
        # Finish cold objects before spending another attempt on a growing log
        # that was already indexed. Selection still uses the complete snapshot.
        for item in sorted(objects, key=lambda item: str(item["Key"]) in known):
            check_timeout()
            key = str(item["Key"])
            # No stable identity means no reuse, even for size-preserving writes.
            fingerprint = json.dumps(
                [
                    item.get("ETag") or uuid.uuid4().hex,
                    item.get("Size"),
                    str(item.get("LastModified", "")),
                ]
            )
            expected[key] = fingerprint
            cached = connection.execute(
                "SELECT fingerprint FROM objects WHERE key = ?", (key,)
            ).fetchone()
            if cached == (fingerprint,):
                continue
            path = download(item)
            # Commit each whole object so a timeout on a large cold archive
            # can resume with the next object instead of starting over.
            with connection:
                connection.execute("BEGIN IMMEDIATE")
                if connection.execute(
                    "SELECT generation FROM index_state WHERE singleton = 1"
                ).fetchone() != (generation,):
                    raise ArchivePendingError(
                        "RM index changed after listing; retry this snapshot"
                    )
                connection.execute("DELETE FROM records WHERE key = ?", (key,))
                try:
                    with open_log(path) as stream:
                        for number, raw_line in enumerate(stream):
                            check_timeout()
                            line = normalize_log_line(raw_line)
                            app = _application(line)
                            if app is not None:
                                connection.execute(
                                    "INSERT INTO records VALUES (?, ?, ?, ?)",
                                    (key, number, app, line),
                                )
                except (EOFError, gzip.BadGzipFile, zlib.error) as error:
                    raise ArchivePendingError(
                        "ResourceManager archive is not readable in full"
                    ) from error
                path.unlink()
                connection.execute(
                    "INSERT OR REPLACE INTO objects VALUES (?, ?)", (key, fingerprint)
                )
                connection.execute(
                    "UPDATE index_state SET generation = generation + 1 WHERE singleton = 1"
                )
                generation += 1
                changed += 1
        # Fence selection against another refresher replacing an object after
        # we indexed it. Never mix two versions of the same archive snapshot.
        with connection:
            connection.execute("BEGIN IMMEDIATE")
            if connection.execute(
                "SELECT generation FROM index_state WHERE singleton = 1"
            ).fetchone() != (generation,):
                raise ArchivePendingError(
                    "RM index changed after listing; retry this snapshot"
                )
            actual = dict(connection.execute("SELECT key, fingerprint FROM objects"))
            if any(
                actual.get(key) != fingerprint for key, fingerprint in expected.items()
            ):
                raise ArchivePendingError(
                    "RM index changed concurrently; retry this snapshot"
                )
            stale_keys = actual.keys() - expected.keys()
            for key in stale_keys:
                connection.execute("DELETE FROM records WHERE key = ?", (key,))
                connection.execute("DELETE FROM objects WHERE key = ?", (key,))
            if stale_keys:
                connection.execute(
                    "UPDATE index_state SET generation = generation + 1 WHERE singleton = 1"
                )
            destination.parent.mkdir(parents=True, exist_ok=True)
            with destination.open("w", encoding="utf-8") as output:
                for (line,) in connection.execute(
                    "SELECT text FROM records WHERE app IN ('', ?) ORDER BY key, line",
                    (application_id,),
                ):
                    check_timeout()
                    output.write(line.rstrip("\n") + "\n")
    return destination, changed
