# skill_marker

[English](README.md) | 简体中文

`skill_marker` 提供了一个用于标准 `marker-pdf` 转换流程的 Codex skill。

## 包含的 Skill

- `standard-marker-conversion`

主要文件：

- `standard-marker-conversion/SKILL.md`
- `standard-marker-conversion/scripts/marker-standard.sh`
- `standard-marker-conversion/agents/openai.yaml`

## 前置条件

- 已安装 Codex
- 系统可用 `conda`
- 可用的 conda 环境（默认 `ke`）且已安装 `marker-pdf`
- 首次运行可访问网络（下载模型）
- 标准 marker 流程建议至少 8 GB 内存，更推荐 16 GB

## 安装 marker-pdf

创建并准备默认 `ke` 环境：

```bash
conda create -n ke python=3.10 -y
conda run -n ke python -m pip install -U pip
conda run -n ke python -m pip install marker-pdf psutil
```

验证安装：

```bash
conda run -n ke marker_single --help
```

可选（推荐）设置可写模型缓存目录：

```bash
mkdir -p /mnt/e/.cache/datalab/models
```

## 在其他电脑安装

1. 克隆仓库：

```bash
git clone https://github.com/senlanke/skill_marker.git
```

2. 将 skill 目录复制到 Codex 技能目录：

```bash
mkdir -p ~/.codex/skills
cp -r skill_marker/standard-marker-conversion ~/.codex/skills/
```

3. 重启 Codex，让新 skill 生效。

## 使用 Skill

在 Codex 提示里明确要求使用该 skill，例如：

- `Use standard-marker-conversion to convert /path/to/a.pdf to markdown.`

也可以直接运行脚本：

```bash
~/.codex/skills/standard-marker-conversion/scripts/marker-standard.sh \
  --mode single \
  --input "/path/to/file.pdf" \
  --output-dir "/path/to/output"
```

批量模式：

```bash
~/.codex/skills/standard-marker-conversion/scripts/marker-standard.sh \
  --mode batch \
  --input "/path/to/pdf_folder" \
  --output-dir "/path/to/output"
```

## 常见问题

- `Killed` / 退出码 `137`：通常是内存不足。请释放内存、增大 swap，或缩小批量。
- `PermissionError` 缓存路径报错：请使用可写缓存目录，例如 `/mnt/e/.cache/datalab/models`。
- 模型下载失败：检查代理与网络连通性。
