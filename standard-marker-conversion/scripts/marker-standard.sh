#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  marker-standard.sh --mode <single|batch> --input <path> --output-dir <path> [--cache-dir <path>] [--conda-env <name>] [-- ...extra marker args]

Examples:
  marker-standard.sh --mode single --input "/data/a.pdf" --output-dir "/data/out"
  marker-standard.sh --mode batch --input "/data/pdfs" --output-dir "/data/out" -- --max_files 20

Environment defaults:
  MARKER_CONDA_ENV       Default conda env name (fallback: ke)
  MARKER_MODEL_CACHE_DIR Default model cache dir
                         (fallback: ${XDG_CACHE_HOME:-$HOME/.cache}/datalab/models)
  MARKER_FONT_PATH       Font file path for marker
                         (fallback: <cache-dir>/fonts/GoNotoCurrent-Regular.ttf)
USAGE
}

mode=""
input=""
output_dir=""
cache_dir="${MARKER_MODEL_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/datalab/models}"
conda_env="${MARKER_CONDA_ENV:-ke}"
font_path="${MARKER_FONT_PATH:-${cache_dir}/fonts/GoNotoCurrent-Regular.ttf}"
extra_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      mode="${2:-}"
      shift 2
      ;;
    --input)
      input="${2:-}"
      shift 2
      ;;
    --output-dir)
      output_dir="${2:-}"
      shift 2
      ;;
    --cache-dir)
      cache_dir="${2:-}"
      shift 2
      ;;
    --conda-env)
      conda_env="${2:-}"
      shift 2
      ;;
    --)
      shift
      extra_args=("$@")
      break
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

if [[ -z "$mode" || -z "$input" || -z "$output_dir" ]]; then
  usage
  exit 2
fi

if [[ "$mode" != "single" && "$mode" != "batch" ]]; then
  echo "--mode must be single or batch" >&2
  exit 2
fi

if ! command -v conda >/dev/null 2>&1; then
  echo "conda not found in PATH" >&2
  exit 127
fi

if [[ ! -e "$input" ]]; then
  echo "Input path does not exist: $input" >&2
  exit 2
fi

mkdir -p "$output_dir" "$cache_dir" "$(dirname "$font_path")"

if [[ -r /proc/meminfo ]]; then
  mem_kb=$(awk '/MemTotal/{print $2}' /proc/meminfo)
  if [[ -n "$mem_kb" ]] && (( mem_kb < 8000000 )); then
    echo "[WARN] Total memory < 8GB; standard marker may be unstable on large PDFs." >&2
  fi
fi

base_cmd=(conda run -n "$conda_env" env MODEL_CACHE_DIR="$cache_dir" FONT_PATH="$font_path")

if [[ "$mode" == "single" ]]; then
  cmd=("${base_cmd[@]}" marker_single "$input" --output_dir "$output_dir" --output_format markdown --disable_multiprocessing)
else
  if [[ ! -d "$input" ]]; then
    echo "Batch mode requires --input to be a directory: $input" >&2
    exit 2
  fi
  cmd=("${base_cmd[@]}" marker "$input" --output_dir "$output_dir" --output_format markdown --disable_multiprocessing --skip_existing)
fi

if [[ ${#extra_args[@]} -gt 0 ]]; then
  cmd+=("${extra_args[@]}")
fi

echo "[INFO] Running: ${cmd[*]}"
"${cmd[@]}"
