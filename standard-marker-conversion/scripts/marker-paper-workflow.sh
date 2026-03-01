#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  marker-paper-workflow.sh --input <pdf> --output-dir <dir> [options]

Options:
  --input <pdf>           Input PDF file
  --output-dir <dir>      Output directory
  --conda-env <name>      Conda env name (default from MARKER_CONDA_ENV or ke)
  --cache-dir <path>      Model cache dir (default from MARKER_MODEL_CACHE_DIR)
  --font-path <path>      Font path (default from MARKER_FONT_PATH)
  --author <text>         Optional author override
  --year <text>           Optional year override
  --title <text>          Optional title override
  -h, --help              Show this help

Workflow:
  1) Convert PDF to Markdown with marker_single (images enabled by default)
  2) Rename markdown to "作者—年份—论文名.md" (metadata first, fallback to filename)
  3) Keep only images referenced in markdown, delete extra saved images
  4) Validate final format and output location
USAGE
}

input=""
output_dir=""
conda_env="${MARKER_CONDA_ENV:-ke}"
cache_dir="${MARKER_MODEL_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/datalab/models}"
font_path="${MARKER_FONT_PATH:-${cache_dir}/fonts/GoNotoCurrent-Regular.ttf}"
author_override=""
year_override=""
title_override=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)
      input="${2:-}"
      shift 2
      ;;
    --output-dir)
      output_dir="${2:-}"
      shift 2
      ;;
    --conda-env)
      conda_env="${2:-}"
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
    --author)
      author_override="${2:-}"
      shift 2
      ;;
    --year)
      year_override="${2:-}"
      shift 2
      ;;
    --title)
      title_override="${2:-}"
      shift 2
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

if [[ -z "$input" || -z "$output_dir" ]]; then
  usage
  exit 2
fi

if [[ ! -f "$input" ]]; then
  echo "[ERROR] Input PDF not found: $input" >&2
  exit 2
fi

if ! command -v conda >/dev/null 2>&1; then
  echo "[ERROR] conda not found in PATH" >&2
  exit 127
fi

mkdir -p "$output_dir" "$cache_dir" "$(dirname "$font_path")"

tmp_root="$(mktemp -d "${output_dir%/}/.marker_work_XXXXXX")"
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

echo "[INFO] Step 1/4: Convert PDF with marker_single"
conda run -n "$conda_env" env MODEL_CACHE_DIR="$cache_dir" FONT_PATH="$font_path" \
  marker_single "$input" \
  --output_dir "$tmp_root" \
  --output_format markdown \
  --disable_multiprocessing

md_count="$(find "$tmp_root" -type f -name '*.md' | wc -l | tr -d ' ')"
if [[ "$md_count" != "1" ]]; then
  echo "[ERROR] Expected exactly 1 markdown file, found: $md_count" >&2
  exit 2
fi

md_path="$(find "$tmp_root" -type f -name '*.md' | head -n 1)"
work_dir="$(dirname "$md_path")"
old_base="$(basename "$md_path" .md)"
meta_path="$work_dir/${old_base}_meta.json"

new_base="$(
  conda run -n "$conda_env" python - "$input" "$author_override" "$year_override" "$title_override" <<'PY'
import json
import re
import sys
from pathlib import Path

pdf_path, a_override, y_override, t_override = sys.argv[1:5]

def sanitize(text, default_value):
    text = (text or "").strip()
    text = re.sub(r'[<>:"/\\|?*]+', " ", text)
    text = re.sub(r"\s+", " ", text).strip(" .")
    return text if text else default_value

def extract_year(text):
    if not text:
        return None
    m = re.search(r"(19|20)\d{2}", str(text))
    return m.group(0) if m else None

def parse_filename(stem):
    patterns = [
        r"^\s*(?P<a>.+?)\s*[—–-]\s*(?P<y>(?:19|20)\d{2})\s*[—–-]\s*(?P<t>.+?)\s*$",
        r"^\s*(?P<a>.+?)\s*_\s*(?P<y>(?:19|20)\d{2})\s*_\s*(?P<t>.+?)\s*$",
    ]
    for p in patterns:
        m = re.match(p, stem)
        if m:
            return m.group("a"), m.group("y"), m.group("t")
    return None, None, None

author = a_override.strip() or None
year = y_override.strip() or None
title = t_override.strip() or None

meta = {}
try:
    Reader = None
    try:
        from pypdf import PdfReader as Reader
    except Exception:
        try:
            from PyPDF2 import PdfReader as Reader
        except Exception:
            Reader = None
    if Reader is not None:
        reader = Reader(pdf_path)
        raw = reader.metadata or {}
        for k, v in raw.items():
            key = str(k).strip("/").lower()
            meta[key] = str(v)
except Exception:
    pass

if not author:
    author = (meta.get("author") or "").strip() or None
if not title:
    title = (meta.get("title") or "").strip() or None
if not year:
    year = extract_year(meta.get("creationdate")) or extract_year(meta.get("moddate"))

stem = Path(pdf_path).stem
f_author, f_year, f_title = parse_filename(stem)

if not author and f_author:
    author = f_author
if not year and f_year:
    year = f_year
if not title and f_title:
    title = f_title

if not year:
    year = extract_year(stem)

author = sanitize(author, "UnknownAuthor")
year = sanitize(year, "UnknownYear")
title = sanitize(title, sanitize(stem, "Untitled"))

print(f"{author}—{year}—{title}")
PY
)"

if [[ -z "$new_base" ]]; then
  echo "[ERROR] Failed to build target filename." >&2
  exit 2
fi

echo "[INFO] Step 2/4: Rename markdown file"
new_md="$work_dir/${new_base}.md"
mv "$md_path" "$new_md"
if [[ -f "$meta_path" ]]; then
  mv "$meta_path" "$work_dir/${new_base}_meta.json"
fi

echo "[INFO] Step 3/4: Remove extra images not referenced in markdown"
cleanup_report="$(
  conda run -n "$conda_env" python - "$new_md" "$work_dir" <<'PY'
import json
import os
import re
import sys
from urllib.parse import unquote

md_path = os.path.abspath(sys.argv[1])
root_dir = os.path.abspath(sys.argv[2])
md_dir = os.path.dirname(md_path)

filename = os.path.basename(md_path)
if not re.match(r"^.+—.+—.+\.md$", filename):
    print("[ERROR] Markdown filename does not match 作者—年份—论文名.md")
    sys.exit(2)

with open(md_path, "r", encoding="utf-8") as f:
    text = f.read()

if not text.strip():
    print("[ERROR] Markdown file is empty.")
    sys.exit(2)

img_md = re.findall(r"!\[[^\]]*\]\(([^)]+)\)", text)
img_html = re.findall(r"<img[^>]+src=[\"']([^\"']+)[\"']", text, flags=re.IGNORECASE)
raw_refs = img_md + img_html

def norm_ref(ref):
    ref = ref.strip().strip("<>").strip()
    if not ref:
        return None
    if ref.startswith(("http://", "https://", "data:", "#")):
        return None
    ref = ref.split("#", 1)[0].split("?", 1)[0].strip()
    if not ref:
        return None
    ref = unquote(ref)
    abs_ref = os.path.normpath(os.path.abspath(os.path.join(md_dir, ref)))
    return abs_ref

refs = set()
for ref in raw_refs:
    n = norm_ref(ref)
    if n:
        refs.add(n)

image_ext = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".tif", ".tiff", ".svg"}
images = set()
for d, _, files in os.walk(root_dir):
    for name in files:
        if os.path.splitext(name)[1].lower() in image_ext:
            images.add(os.path.abspath(os.path.join(d, name)))

missing = sorted([p for p in refs if not os.path.exists(p)])
if missing:
    print("[ERROR] Markdown references missing image files:")
    for p in missing:
        print(f"  - {p}")
    sys.exit(2)

extracted_count = len(images)
referenced_count = len(images.intersection(refs))
if extracted_count > 0 and referenced_count == 0:
    print("[ERROR] Images were extracted but none are referenced in markdown.")
    sys.exit(2)

extras = sorted(images - refs)
for p in extras:
    os.remove(p)

remaining = set()
for d, _, files in os.walk(root_dir):
    for name in files:
        if os.path.splitext(name)[1].lower() in image_ext:
            remaining.add(os.path.abspath(os.path.join(d, name)))

leftover = sorted(remaining - refs)
if leftover:
    print("[ERROR] Found unreferenced images after cleanup:")
    for p in leftover:
        print(f"  - {p}")
    sys.exit(2)

print(json.dumps({
    "extracted_images": extracted_count,
    "referenced_images": referenced_count,
    "deleted_images": len(extras),
    "format_check": "ok"
}, ensure_ascii=False))
PY
)"
echo "[INFO] Cleanup/format report: $cleanup_report"

echo "[INFO] Step 4/4: Finalize output"
final_dir="$output_dir/$new_base"
if [[ -e "$final_dir" ]]; then
  echo "[ERROR] Target directory already exists: $final_dir" >&2
  exit 2
fi

mv "$work_dir" "$final_dir"
final_md="$final_dir/$new_base.md"

if [[ ! -s "$final_md" ]]; then
  echo "[ERROR] Final markdown file is missing or empty: $final_md" >&2
  exit 2
fi

rmdir "$tmp_root" 2>/dev/null || true
trap - EXIT

echo "[DONE] Workflow complete."
echo "[DONE] Markdown: $final_md"
echo "[DONE] Directory: $final_dir"
