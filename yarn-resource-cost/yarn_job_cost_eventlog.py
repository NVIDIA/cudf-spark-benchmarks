#!/usr/bin/env python3
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

"""Read Spark rolling event logs without requiring PySpark or python-lz4."""

from __future__ import annotations

import tarfile
from pathlib import Path
from typing import BinaryIO, Iterable, Literal

LZ4_BLOCK_MAGIC = b"LZ4Block"
RAW_BLOCK = 0x10
LZ4_COMPRESSED_BLOCK = 0x20
LZ4_CODEC = "lz4"
ZSTD_CODEC = "zstd"
EventLogCodec = Literal["lz4", "zstd"]
READ_SIZE = 1024 * 1024
MAX_EVENT_LINE_BYTES = 64 * 1024 * 1024


def lz4_decompress_block(src: bytes, expected_len: int) -> bytes:
    out = bytearray()
    index = 0
    while index < len(src):
        token = src[index]
        index += 1
        literal_len = token >> 4
        if literal_len == 15:
            while True:
                extra = src[index]
                index += 1
                literal_len += extra
                if extra != 255:
                    break
        out.extend(src[index : index + literal_len])
        index += literal_len
        if index >= len(src):
            break

        offset = src[index] | (src[index + 1] << 8)
        index += 2
        match_len = token & 0x0F
        if match_len == 15:
            while True:
                extra = src[index]
                index += 1
                match_len += extra
                if extra != 255:
                    break
        match_len += 4
        if offset <= 0 or offset > len(out):
            raise ValueError(f"Invalid LZ4 offset {offset} at compressed offset {index}")
        start = len(out) - offset
        for copy_index in range(match_len):
            out.append(out[start + copy_index])
    if len(out) != expected_len:
        raise ValueError(f"LZ4 block length mismatch: got {len(out)}, expected {expected_len}")
    return bytes(out)


def iter_lz4block_chunks(stream: BinaryIO) -> Iterable[bytes]:
    while True:
        header = stream.read(21)
        if not header:
            return
        if len(header) != 21:
            raise ValueError("Truncated LZ4Block header")
        if header[: len(LZ4_BLOCK_MAGIC)] != LZ4_BLOCK_MAGIC:
            raise ValueError(f"Bad LZ4Block magic: {header[:8]!r}")
        token = header[8]
        compressed_len = int.from_bytes(header[9:13], "little")
        decompressed_len = int.from_bytes(header[13:17], "little")
        if compressed_len == 0 and decompressed_len == 0:
            return
        block = stream.read(compressed_len)
        if len(block) != compressed_len:
            raise ValueError("Truncated LZ4Block payload")
        method = token & 0xF0
        if method == RAW_BLOCK:
            yield block
        elif method == LZ4_COMPRESSED_BLOCK:
            yield lz4_decompress_block(block, decompressed_len)
        else:
            raise ValueError(f"Unsupported LZ4Block token {token:#x}")


def iter_zstd_chunks(stream: BinaryIO) -> Iterable[bytes]:
    try:
        import zstandard
    except ImportError as error:
        raise ValueError(
            "Reading .zstd event logs requires the zstandard package; "
            "run 'python3 -m pip install .' from the bundle directory"
        ) from error
    decompressor = zstandard.ZstdDecompressor()
    with decompressor.stream_reader(
        stream, read_across_frames=True, closefd=False
    ) as reader:
        yield from iter(lambda: reader.read(READ_SIZE), b"")


def iter_text_lines(
    stream: BinaryIO,
    codec: EventLogCodec | None,
    max_line_bytes: int = MAX_EVENT_LINE_BYTES,
) -> Iterable[str]:
    if codec == LZ4_CODEC:
        chunks = iter_lz4block_chunks(stream)
    elif codec == ZSTD_CODEC:
        chunks = iter_zstd_chunks(stream)
    elif codec is None:
        chunks = iter(lambda: stream.read(READ_SIZE), b"")
    else:
        raise ValueError(f"Unsupported event-log compression codec: {codec}")

    pending: list[bytes] = []
    pending_size = 0
    for chunk in chunks:
        for part in chunk.splitlines(keepends=True):
            pending_size += len(part)
            if pending_size > max_line_bytes:
                raise ValueError(
                    f"Event-log line exceeds {max_line_bytes}-byte limit"
                )
            pending.append(part)
            if part.endswith((b"\n", b"\r")):
                yield b"".join(pending).decode(
                    "utf-8", errors="replace"
                ).strip()
                pending.clear()
                pending_size = 0
    if pending:
        line = b"".join(pending).decode("utf-8", errors="replace").strip()
        if line:
            yield line


def normalized_member_name(name: str) -> str:
    while name.startswith("./"):
        name = name[2:]
    return name


def eventlog_codec(name: str) -> EventLogCodec | None:
    suffix = Path(name).suffix.lower()
    if suffix == ".lz4":
        return LZ4_CODEC
    if suffix == ".zstd":
        return ZSTD_CODEC
    return None


def iter_eventlog_streams(
    path: Path,
) -> Iterable[tuple[str, str, BinaryIO, EventLogCodec | None]]:
    if path.is_file() and tarfile.is_tarfile(path):
        with tarfile.open(path, mode="r:*") as tar:
            members = sorted(
                (member for member in tar.getmembers() if member.isfile()),
                key=lambda member: normalized_member_name(member.name),
            )
            for member in members:
                name = normalized_member_name(member.name)
                if not member.isfile() or "/events_" not in name:
                    continue
                extracted = tar.extractfile(member)
                if extracted is None:
                    continue
                app_dir = name.split("/", 1)[0]
                with extracted:
                    yield app_dir, name, extracted, eventlog_codec(name)
        return

    if path.is_dir():
        files = sorted(p for p in path.rglob("events_*") if p.is_file())
    else:
        files = [path]
    for file_path in files:
        rel = file_path.as_posix()
        app_dir = file_path.parent.name if file_path.parent.name.startswith("eventlog_") else file_path.stem
        with file_path.open("rb") as handle:
            yield app_dir, rel, handle, eventlog_codec(file_path.name)
