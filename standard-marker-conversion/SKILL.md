---
name: standard-marker-conversion
description: Use when converting one or more PDFs to Markdown with standard marker-pdf (full model pipeline, not lightweight fallback), including setup and troubleshooting for conda env selection, model cache path, model download, and OOM/proxy/permission issues.
---

# Standard Marker Conversion

## Overview
Run standard `marker` / `marker_single` with the full model pipeline. Do not use monkey-patched or lightweight fallbacks when this skill is selected.

## Paper Workflow (Default)
For paper conversion tasks, use this required workflow:
1. Convert PDF to markdown with standard `marker_single` (image extraction enabled).
2. Rename markdown to `作者—年份—论文名.md`.
   - Priority: PDF metadata (`Author`, `Title`, creation/modification year) -> filename parsing -> fallback placeholders.
3. Ensure images are referenced inside markdown.
4. Delete extra saved images that are not referenced in markdown.
5. Validate final format (filename pattern + non-empty markdown + image reference consistency).

Use the workflow script:

Codex:

```bash
"${CODEX_HOME:-$HOME/.codex}/skills/standard-marker-conversion/scripts/marker-paper-workflow.sh" \
  --input "/path/to/paper.pdf" \
  --output-dir "/path/to/output"
```

Claude Code:

```bash
"${CLAUDE_HOME:-$HOME/.claude}/skills/standard-marker-conversion/scripts/marker-paper-workflow.sh" \
  --input "/path/to/paper.pdf" \
  --output-dir "/path/to/output"
```

## Prepare Environment and Models
Run setup once to install packages and pre-download required models.

Codex:

```bash
"${CODEX_HOME:-$HOME/.codex}/skills/standard-marker-conversion/scripts/setup-marker.sh"
```

Claude Code:

```bash
"${CLAUDE_HOME:-$HOME/.claude}/skills/standard-marker-conversion/scripts/setup-marker.sh"
```

The setup script supports:
- `MARKER_CONDA_ENV` (fallback: `ke`)
- `MARKER_MODEL_CACHE_DIR` (fallback: `${XDG_CACHE_HOME:-$HOME/.cache}/datalab/models`)
- `MARKER_FONT_PATH` (fallback: `<cache-dir>/fonts/GoNotoCurrent-Regular.ttf`)
- `--offline` (no create/install/download; only validate local readiness)

## Quick Start
Use the bundled script from your installed skill directory.

Codex:

```bash
"${CODEX_HOME:-$HOME/.codex}/skills/standard-marker-conversion/scripts/marker-standard.sh" \
  --mode single \
  --input "/path/to/file.pdf" \
  --output-dir "/path/to/output"
```

Claude Code:

```bash
"${CLAUDE_HOME:-$HOME/.claude}/skills/standard-marker-conversion/scripts/marker-standard.sh" \
  --mode single \
  --input "/path/to/file.pdf" \
  --output-dir "/path/to/output"
```

Batch convert a folder:

```bash
"${CODEX_HOME:-$HOME/.codex}/skills/standard-marker-conversion/scripts/marker-standard.sh" \
  --mode batch \
  --input "/path/to/pdf_folder" \
  --output-dir "/path/to/output"
```

For single-paper formatting and validation requirements, prefer `marker-paper-workflow.sh` over `marker-standard.sh`.

## Standard Commands
Single PDF:

```bash
CONDA_ENV="${MARKER_CONDA_ENV:-ke}"
MODEL_CACHE_DIR="${MARKER_MODEL_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/datalab/models}"
mkdir -p "$MODEL_CACHE_DIR"
conda run -n "$CONDA_ENV" env MODEL_CACHE_DIR="$MODEL_CACHE_DIR" \
  marker_single "/path/to/file.pdf" \
  --output_dir "/path/to/output" \
  --output_format markdown \
  --disable_multiprocessing
```

Folder batch:

```bash
CONDA_ENV="${MARKER_CONDA_ENV:-ke}"
MODEL_CACHE_DIR="${MARKER_MODEL_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/datalab/models}"
mkdir -p "$MODEL_CACHE_DIR"
conda run -n "$CONDA_ENV" env MODEL_CACHE_DIR="$MODEL_CACHE_DIR" \
  marker "/path/to/pdf_folder" \
  --output_dir "/path/to/output" \
  --output_format markdown \
  --disable_multiprocessing \
  --skip_existing
```

## Preflight Checklist
- Ensure `conda` is available and the target environment exists (`MARKER_CONDA_ENV`, fallback `ke`).
- Ensure `marker-pdf` is installed in the selected environment.
- Ensure model cache path is writable (`MARKER_MODEL_CACHE_DIR`, fallback `${XDG_CACHE_HOME:-$HOME/.cache}/datalab/models`).
- Ensure marker font path is writable (`MARKER_FONT_PATH`).
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
  - Actions: set `MARKER_MODEL_CACHE_DIR` (or `MODEL_CACHE_DIR` for direct command runs) to a writable path.

- `ProxyError` / download failures from `models.datalab.to`:
  - Root cause: invalid proxy or blocked network.
  - Actions: fix proxy env (`HTTP_PROXY`, `HTTPS_PROXY`) or run in an environment with direct access.

- First run is very slow:
  - Root cause: large model downloads.
  - Actions: wait for download completion; later runs are faster due to cache reuse.
