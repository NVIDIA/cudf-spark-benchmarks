# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

import csv
import hashlib
import io
import json
from pathlib import Path


def write_phase_report(path, header, rows, metrics):
    """Write the user-facing CSV and keep full-score inputs in a companion file."""
    report = io.StringIO(newline='')
    writer = csv.writer(report)
    writer.writerow(header)
    writer.writerows(rows)
    data = report.getvalue().encode('utf-8')
    metadata = Path(f'{path}.metrics.json')
    # Invalidate the previous pair before reusing a report path.
    try:
        metadata.unlink()
    except FileNotFoundError:
        pass
    Path(path).write_bytes(data)
    metadata.write_text(json.dumps({'csv_sha256': hashlib.sha256(data).hexdigest(),
                                    'metrics': metrics}, indent=2) + '\n', encoding='utf-8')


def read_phase_metrics(path):
    data = Path(path).read_bytes()
    try:
        metadata = Path(f'{path}.metrics.json').read_text(encoding='utf-8')
    except FileNotFoundError:
        # Earlier reports from this timing change stored the metrics in CSV rows.
        rows = csv.reader(io.StringIO(data.decode('utf-8'), newline=''))
        return {row[1]: row[2] for row in rows if len(row) == 3}
    record = json.loads(metadata)
    if record['csv_sha256'] != hashlib.sha256(data).hexdigest():
        raise ValueError(f'{path}: CSV and .metrics.json do not match; rerun this phase')
    return record['metrics']
