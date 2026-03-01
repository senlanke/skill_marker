# skill_marker

English | [简体中文](README.zh-CN.md)

`skill_marker` provides a Codex skill for standard `marker-pdf` conversion.

## Included Skill

- `standard-marker-conversion`

Main files:

- `standard-marker-conversion/SKILL.md`
- `standard-marker-conversion/scripts/marker-standard.sh`
- `standard-marker-conversion/agents/openai.yaml`

## Prerequisites

- Codex installed
- `conda` available
- A working conda environment (default: `ke`) with `marker-pdf` installed
- Network access on first run (model download)
- Enough memory for standard marker pipeline (8 GB+ recommended, 16 GB preferred)

## Install on Another Machine

1. Clone this repository:

```bash
git clone https://github.com/senlanke/skill_marker.git
```

2. Copy the skill folder into your Codex skills directory:

```bash
mkdir -p ~/.codex/skills
cp -r skill_marker/standard-marker-conversion ~/.codex/skills/
```

3. Restart Codex so the new skill is discovered.

## Use the Skill

In Codex prompt, ask to use the skill for standard marker conversion. Example:

- `Use standard-marker-conversion to convert /path/to/a.pdf to markdown.`

You can also run the bundled script directly:

```bash
~/.codex/skills/standard-marker-conversion/scripts/marker-standard.sh \
  --mode single \
  --input "/path/to/file.pdf" \
  --output-dir "/path/to/output"
```

Batch mode:

```bash
~/.codex/skills/standard-marker-conversion/scripts/marker-standard.sh \
  --mode batch \
  --input "/path/to/pdf_folder" \
  --output-dir "/path/to/output"
```

## Troubleshooting

- `Killed` / exit code `137`: out-of-memory. Free memory, increase swap, or run smaller batches.
- `PermissionError` on cache paths: use writable cache dir, such as `/mnt/e/.cache/datalab/models`.
- Model download failures: check proxy/network settings.
