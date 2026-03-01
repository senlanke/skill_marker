---
name: standard-marker-conversion
description: Use when converting one or more PDFs to Markdown with standard marker-pdf (full model pipeline, not lightweight fallback), especially in the ke conda environment where cache path, model download, and OOM/proxy/permission troubleshooting are needed.
---

# Standard Marker Conversion

## Overview
Run standard `marker` / `marker_single` with the full model pipeline. Do not use monkey-patched or lightweight fallbacks when this skill is selected.

## Quick Start
Use the bundled script for the default standard flow:

```bash
/home/kesl/.codex/skills/standard-marker-conversion/scripts/marker-standard.sh \
  --mode single \
  --input "/path/to/file.pdf" \
  --output-dir "/path/to/output"
```

Batch convert a folder:

```bash
/home/kesl/.codex/skills/standard-marker-conversion/scripts/marker-standard.sh \
  --mode batch \
  --input "/path/to/pdf_folder" \
  --output-dir "/path/to/output"
```

## Standard Commands
Single PDF:

```bash
conda run -n ke env MODEL_CACHE_DIR=/mnt/e/.cache/datalab/models \
  marker_single "/path/to/file.pdf" \
  --output_dir "/path/to/output" \
  --output_format markdown \
  --disable_multiprocessing
```

Folder batch:

```bash
conda run -n ke env MODEL_CACHE_DIR=/mnt/e/.cache/datalab/models \
  marker "/path/to/pdf_folder" \
  --output_dir "/path/to/output" \
  --output_format markdown \
  --disable_multiprocessing \
  --skip_existing
```

## Preflight Checklist
- Ensure `conda` is available and environment `ke` exists.
- Ensure `marker-pdf` is installed in `ke`.
- Ensure model cache path is writable. Default: `/mnt/e/.cache/datalab/models`.
- Ensure network access for first-run model download.
- Prefer at least 8 GB RAM (16 GB recommended for stability on larger PDFs).

## Verification
- Confirm target markdown file exists and is non-empty:

```bash
test -s "/path/to/output/file.md"
```

- Optionally inspect first lines:

```bash
sed -n '1,30p' "/path/to/output/file.md"
```

## Troubleshooting
- `exit code 137` / `Killed`:
  - Root cause: OOM.
  - Actions: free memory, increase swap, run one file at a time, keep `--disable_multiprocessing`.

- `PermissionError` on cache/font paths:
  - Root cause: non-writable default directories.
  - Actions: set `MODEL_CACHE_DIR` to a writable path (for example `/mnt/e/.cache/datalab/models`).

- `ProxyError` / download failures from `models.datalab.to`:
  - Root cause: invalid proxy or blocked network.
  - Actions: fix proxy env (`HTTP_PROXY`, `HTTPS_PROXY`) or run in an environment with direct access.

- First run is very slow:
  - Root cause: large model downloads.
  - Actions: wait for download completion; later runs are faster due to cache reuse.
