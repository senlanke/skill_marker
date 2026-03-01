# skill_marker

[English](README.md) | 简体中文

`skill_marker` 提供了一个可复用的标准 `marker-pdf` 转换 skill，可同时用于 Codex 与 Claude Code。

## 包含的 Skill

- `standard-marker-conversion`

主要文件：

- `standard-marker-conversion/SKILL.md`
- `standard-marker-conversion/scripts/marker-standard.sh`
- `standard-marker-conversion/agents/openai.yaml`

## 前置条件

- 已安装 Codex 或 Claude Code
- 系统可用 `conda`
- 可用的 marker conda 环境（`MARKER_CONDA_ENV`，默认 `ke`）
- 首次运行可访问网络（下载模型）
- 标准 marker 流程建议至少 8 GB 内存，更推荐 16 GB

## 一键准备（安装 + 模型下载）

该安装脚本会一次性准备所有必要内容：
- 创建 conda 环境（不存在时）
- 安装 `marker-pdf` 与 `psutil`
- 下载 marker 字体
- 预下载 Surya 必需模型（`layout`、`text_recognition`、`text_detection`、`ocr_error_detection`、`table_recognition`）

克隆仓库后执行：

```bash
cd skill_marker
bash standard-marker-conversion/scripts/setup-marker.sh
```

可用参数：

```bash
bash standard-marker-conversion/scripts/setup-marker.sh --help
```

## 安装 Skill（Codex 与 Claude Code）

1. 克隆仓库：

```bash
git clone https://github.com/senlanke/skill_marker.git
cd skill_marker
```

2. 安装到 Codex skills 目录：

```bash
CODEX_SKILLS_DIR="${CODEX_HOME:-$HOME/.codex}/skills"
mkdir -p "$CODEX_SKILLS_DIR"
cp -r standard-marker-conversion "$CODEX_SKILLS_DIR/"
```

3. 安装到 Claude Code skills 目录：

```bash
CLAUDE_SKILLS_DIR="${CLAUDE_HOME:-$HOME/.claude}/skills"
mkdir -p "$CLAUDE_SKILLS_DIR"
cp -r standard-marker-conversion "$CLAUDE_SKILLS_DIR/"
```

4. 重启 Codex 和/或 Claude Code。

## 使用 Skill

在提示词中明确要求使用 `standard-marker-conversion`。

直接运行脚本（Codex 安装路径）：

```bash
"${CODEX_HOME:-$HOME/.codex}/skills/standard-marker-conversion/scripts/marker-standard.sh" \
  --mode single \
  --input "/path/to/file.pdf" \
  --output-dir "/path/to/output"
```

直接运行脚本（Claude Code 安装路径）：

```bash
"${CLAUDE_HOME:-$HOME/.claude}/skills/standard-marker-conversion/scripts/marker-standard.sh" \
  --mode batch \
  --input "/path/to/pdf_folder" \
  --output-dir "/path/to/output"
```

## 配置（无主机硬编码）

- `MARKER_CONDA_ENV`：默认 conda 环境名（默认 `ke`）
- `MARKER_MODEL_CACHE_DIR`：模型缓存目录（默认 `${XDG_CACHE_HOME:-$HOME/.cache}/datalab/models`）
- `MARKER_FONT_PATH`：marker 字体路径（默认 `<cache-dir>/fonts/GoNotoCurrent-Regular.ttf`）
- `MARKER_PYTHON_VERSION`：`setup-marker.sh` 创建环境时使用的 Python 版本（默认 `3.10`）

## 常见问题

- `Killed` / 退出码 `137`：通常是内存不足。请释放内存、增大 swap，或缩小批量。
- `PermissionError` 缓存路径报错：请使用可写 `MARKER_MODEL_CACHE_DIR`。
- 模型下载失败：检查代理与网络连通性。
