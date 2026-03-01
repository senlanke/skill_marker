# skill_marker

English | [简体中文](README.zh-CN.md)

`skill_marker` provides a reusable skill for standard `marker-pdf` conversion in both Codex and Claude Code.

## Included Skill

- `standard-marker-conversion`

Main files:

- `standard-marker-conversion/SKILL.md`
- `standard-marker-conversion/scripts/marker-standard.sh`
- `standard-marker-conversion/agents/openai.yaml`

## Prerequisites

- Codex or Claude Code installed
- `conda` available
- A conda environment for marker (`MARKER_CONDA_ENV`, default: `ke`)
- Network access on first run (model download)
- Enough memory for standard marker pipeline (8 GB+ recommended, 16 GB preferred)

## One-Command Setup (Install + Model Download)

This setup script prepares all required content:
- creates conda env (if missing)
- installs `marker-pdf` and `psutil`
- downloads marker font
- pre-downloads required Surya models (`layout`, `text_recognition`, `text_detection`, `ocr_error_detection`, `table_recognition`)

After cloning the repo:

```bash
cd skill_marker
bash standard-marker-conversion/scripts/setup-marker.sh
```

Useful options:

```bash
bash standard-marker-conversion/scripts/setup-marker.sh --help
```

Offline validation (no create/install/download):

```bash
bash standard-marker-conversion/scripts/setup-marker.sh --offline
```

## Install This Skill (Codex and Claude Code)

1. Clone this repository:

```bash
git clone https://github.com/senlanke/skill_marker.git
cd skill_marker
```

2. Install into Codex skills directory:

```bash
CODEX_SKILLS_DIR="${CODEX_HOME:-$HOME/.codex}/skills"
mkdir -p "$CODEX_SKILLS_DIR"
cp -r standard-marker-conversion "$CODEX_SKILLS_DIR/"
```

3. Install into Claude Code skills directory:

```bash
CLAUDE_SKILLS_DIR="${CLAUDE_HOME:-$HOME/.claude}/skills"
mkdir -p "$CLAUDE_SKILLS_DIR"
cp -r standard-marker-conversion "$CLAUDE_SKILLS_DIR/"
```

4. Restart Codex and/or Claude Code.

## Use the Skill

In prompts, explicitly ask to use `standard-marker-conversion`.

Run script directly (Codex install path):

```bash
"${CODEX_HOME:-$HOME/.codex}/skills/standard-marker-conversion/scripts/marker-standard.sh" \
  --mode single \
  --input "/path/to/file.pdf" \
  --output-dir "/path/to/output"
```

Run script directly (Claude Code install path):

```bash
"${CLAUDE_HOME:-$HOME/.claude}/skills/standard-marker-conversion/scripts/marker-standard.sh" \
  --mode batch \
  --input "/path/to/pdf_folder" \
  --output-dir "/path/to/output"
```

## Configuration (No Host-Specific Hardcoding)

- `MARKER_CONDA_ENV`: default conda env name (fallback `ke`)
- `MARKER_MODEL_CACHE_DIR`: model cache path (fallback `${XDG_CACHE_HOME:-$HOME/.cache}/datalab/models`)
- `MARKER_FONT_PATH`: marker font path (fallback `<cache-dir>/fonts/GoNotoCurrent-Regular.ttf`)
- `MARKER_PYTHON_VERSION`: python version used by `setup-marker.sh` when creating env (fallback `3.10`)

## Troubleshooting

- `Killed` / exit code `137`: out-of-memory. Free memory, increase swap, or run smaller batches.
- `PermissionError` on cache paths: use writable `MARKER_MODEL_CACHE_DIR`.
- Model download failures: check proxy/network settings.
