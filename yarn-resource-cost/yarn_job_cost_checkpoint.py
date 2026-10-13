#!/usr/bin/env python3
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

"""Disposable JSON checkpoints for sequential Spark event-log parsing."""

from __future__ import annotations

import hashlib
import json
import os
import tempfile
from dataclasses import asdict
from pathlib import Path


def stream_identity(stream, source: Path) -> tuple[int, ...]:
    """Identify a local snapshot (including members of a local tar archive)."""
    try:
        stat = os.fstat(stream.fileno())
    except (AttributeError, OSError):
        stat = source.stat()
    return stat.st_dev, stat.st_ino, stat.st_size, stat.st_mtime_ns


class EventCheckpoints:
    """Each key includes all preceding segments; changes invalidate successors.

    Only successful whole segments are saved, before final validation mutates
    their metadata. JSON, never pickle, keeps cache contents non-executable.
    """

    SET_FIELDS = ("event_segments", "unsupported_resource_profile_ids")

    def __init__(self, directory: Path, source: str):
        self.directory = directory / "event-metadata-v1"
        self.directory.mkdir(parents=True, exist_ok=True, mode=0o700)
        self.digest = hashlib.sha256(source.encode()).hexdigest()
        self.usable = True
        self.hits = 0

    def advance(self, app_dir: str, member: str, identity: tuple[int, ...]) -> None:
        self.digest = hashlib.sha256(
            json.dumps([self.digest, app_dir, Path(member).name, identity]).encode()
        ).hexdigest()

    def load(self, application_type, executor_type):
        if not self.usable:
            return None
        try:
            data = json.loads(self.path.read_text(encoding="utf-8"))
            for field in self.SET_FIELDS:
                data[field] = set(data[field])
            data["executors"] = {
                key: executor_type(**value) for key, value in data["executors"].items()
            }
            application = application_type(**data)
            self.hits += 1
            return application
        except (FileNotFoundError, ValueError, TypeError, KeyError, AttributeError):
            return None

    @property
    def path(self) -> Path:
        return self.directory / f"{self.digest}.json"

    def save(self, application) -> None:
        if not self.usable:
            return
        data = asdict(application)
        for field in self.SET_FIELDS:
            data[field] = sorted(data[field])
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", dir=self.directory, delete=False
        ) as output:
            temporary = Path(output.name)
            try:
                json.dump(data, output)
                output.flush()
                temporary.replace(self.path)
            finally:
                temporary.unlink(missing_ok=True)
