#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  setup-marker.sh [options]

Options:
  --conda-env <name>          Conda environment name
  --python-version <version>  Python version for new env (default: 3.10)
  --cache-dir <path>          Model cache directory
  --font-path <path>          Font path used by marker
  --offline                   Offline validation mode (no create/install/download)
  --skip-conda-create         Do not create conda env if missing
  --skip-model-download       Skip model pre-download
  --skip-font-download        Skip font pre-download
  -h, --help                  Show this help

Environment defaults:
  MARKER_CONDA_ENV            Default conda env name (fallback: ke)
  MARKER_PYTHON_VERSION       Default python version (fallback: 3.10)
  MARKER_MODEL_CACHE_DIR      Default model cache dir
                              (fallback: ${XDG_CACHE_HOME:-$HOME/.cache}/datalab/models)
  MARKER_FONT_PATH            Default marker font path
                              (fallback: <cache-dir>/fonts/GoNotoCurrent-Regular.ttf)

Example:
  setup-marker.sh --conda-env marker --python-version 3.10
USAGE
}

conda_env="${MARKER_CONDA_ENV:-ke}"
python_version="${MARKER_PYTHON_VERSION:-3.10}"
cache_dir="${MARKER_MODEL_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/datalab/models}"
font_path="${MARKER_FONT_PATH:-${cache_dir}/fonts/GoNotoCurrent-Regular.ttf}"
skip_conda_create=0
skip_model_download=0
skip_font_download=0
offline=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --conda-env)
      conda_env="${2:-}"
      shift 2
      ;;
    --python-version)
      python_version="${2:-}"
      shift 2
      ;;
    --cache-dir)
      cache_dir="${2:-}"
      shift 2
      ;;
    --font-path)
      font_path="${2:-}"
      shift 2
      ;;
    --offline)
      offline=1
      shift
      ;;
    --skip-conda-create)
      skip_conda_create=1
      shift
      ;;
    --skip-model-download)
      skip_model_download=1
      shift
      ;;
    --skip-font-download)
      skip_font_download=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if ! command -v conda >/dev/null 2>&1; then
  echo "conda not found in PATH" >&2
  exit 127
fi

if [[ $offline -eq 1 ]]; then
  skip_conda_create=1
  skip_model_download=1
  skip_font_download=1
fi

if [[ $offline -eq 0 ]]; then
  mkdir -p "$cache_dir" "$(dirname "$font_path")"
fi

if conda run -n "$conda_env" python -V >/dev/null 2>&1; then
  echo "[INFO] Conda env exists: $conda_env"
else
  if [[ $skip_conda_create -eq 1 ]]; then
    echo "[ERROR] Conda env '$conda_env' does not exist and --skip-conda-create was set." >&2
    exit 2
  fi
  echo "[INFO] Creating conda env: $conda_env (python=$python_version)"
  conda create -n "$conda_env" "python=$python_version" -y
fi

if [[ $offline -eq 0 ]]; then
  echo "[INFO] Installing marker dependencies in env '$conda_env'"
  conda run -n "$conda_env" python -m pip install -U pip
  conda run -n "$conda_env" python -m pip install marker-pdf psutil
else
  echo "[INFO] Offline mode: skip dependency install"
fi

if [[ $skip_font_download -eq 0 ]]; then
  echo "[INFO] Downloading marker font to: $font_path"
  conda run -n "$conda_env" env FONT_PATH="$font_path" python - <<'PY'
from marker.util import download_font
from marker.settings import settings

download_font()
print(f"[INFO] Font ready: {settings.FONT_PATH}")
PY
else
  echo "[INFO] Skipping font download (--skip-font-download)"
fi

if [[ $skip_model_download -eq 0 ]]; then
  echo "[INFO] Pre-downloading Surya models to: $cache_dir"
  conda run -n "$conda_env" env MODEL_CACHE_DIR="$cache_dir" python - <<'PY'
import os
from surya.settings import settings
from surya.common.s3 import download_directory

checkpoints = [
    settings.LAYOUT_MODEL_CHECKPOINT,
    settings.RECOGNITION_MODEL_CHECKPOINT,
    settings.DETECTOR_MODEL_CHECKPOINT,
    settings.OCR_ERROR_MODEL_CHECKPOINT,
    settings.TABLE_REC_MODEL_CHECKPOINT,
]

seen = set()
for cp in checkpoints:
    if not cp.startswith("s3://"):
        print(f"[WARN] Skip non-s3 checkpoint: {cp}")
        continue
    rel = cp[len("s3://") :]
    if rel in seen:
        continue
    seen.add(rel)
    local_path = os.path.join(settings.MODEL_CACHE_DIR, rel)
    os.makedirs(local_path, exist_ok=True)
    print(f"[INFO] Downloading {cp} -> {local_path}")
    download_directory(rel, local_path)

print("[INFO] Model pre-download complete.")
PY
else
  echo "[INFO] Skipping model download (--skip-model-download)"
fi

if [[ $offline -eq 1 ]]; then
  echo "[INFO] Offline mode: validating local font and model cache completeness"
  if [[ ! -f "$font_path" ]]; then
    echo "[ERROR] Font file not found: $font_path" >&2
    exit 2
  fi

  conda run -n "$conda_env" env MODEL_CACHE_DIR="$cache_dir" python - <<'PY'
import os
import sys
from surya.settings import settings
from surya.common.s3 import check_manifest

checkpoints = [
    settings.LAYOUT_MODEL_CHECKPOINT,
    settings.RECOGNITION_MODEL_CHECKPOINT,
    settings.DETECTOR_MODEL_CHECKPOINT,
    settings.OCR_ERROR_MODEL_CHECKPOINT,
    settings.TABLE_REC_MODEL_CHECKPOINT,
]

missing = []
seen = set()
for cp in checkpoints:
    if not cp.startswith("s3://"):
        continue
    rel = cp[len("s3://") :]
    if rel in seen:
        continue
    seen.add(rel)
    local_path = os.path.join(settings.MODEL_CACHE_DIR, rel)
    if not check_manifest(local_path):
        missing.append((cp, local_path))

if missing:
    print("[ERROR] Missing or incomplete model directories:")
    for cp, local_path in missing:
        print(f"  - {cp} -> {local_path}")
    sys.exit(2)

print("[INFO] Offline model cache validation passed.")
PY
fi

echo "[INFO] Verifying marker command"
conda run -n "$conda_env" env MODEL_CACHE_DIR="$cache_dir" FONT_PATH="$font_path" marker_single --help >/dev/null

echo "[DONE] Marker setup complete."
echo "[DONE] CONDA ENV: $conda_env"
echo "[DONE] MODEL CACHE: $cache_dir"
echo "[DONE] FONT PATH: $font_path"
echo "[DONE] Recommended exports:"
echo "       export MARKER_CONDA_ENV=\"$conda_env\""
echo "       export MARKER_MODEL_CACHE_DIR=\"$cache_dir\""
echo "       export MARKER_FONT_PATH=\"$font_path\""
