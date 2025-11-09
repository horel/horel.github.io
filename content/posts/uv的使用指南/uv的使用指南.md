---
title: "uv的使用指南"
comment: false
weight: 0
date: 2025-11-09T22:45:08+08:00
# 由 enableGitInfo 替代
# lastmod: 9000-11-11
# draft: false
# math: true
# featuredImage: ""
# featuredImagePreview: ""
# keywords: [""]
categories: ["环境"]
tags:
  - 环境
---

## 安装
- Archlinux
```bash
sudo pacman -S uv
```
- Windows
```powershell
winget install -i astral-sh.uv
```

## python版本管理
列举可安装版本
```bash
uv python list
```
安装指定版本
```bash
uv python install 3.12
```
> 装好的解释器放在 ~/.local/share/uv/python，无需 root，与系统 Python 无关

删除指定版本
```bash
uv python uninstall 3.12
```

## 创建隔离环境
- 直接创建项目
```bash
uv init example --python 3.12
cd example
source .venv/bin/activate
```
- 先创建目录再初始化项目
```bash
cd example
uv python pin 3.12
uv init
uv venv
source .venv/bin/activate
```

## 安装包
```bash
uv add torch==2.9.0+cu130 torchvision==0.24.0 torchaudio==2.9.0 --default-index https://download.pytorch.org/whl/cu130
```

## 退出隔离环境
```bash
deactivate
```

## 复现环境
```bash
uv sync
```