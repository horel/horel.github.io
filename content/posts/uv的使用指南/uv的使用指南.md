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

```
- 先创建目录再初始化项目
```bash
cd example
uv python pin 3.12
uv init
uv venv
```

## 激活环境
- Linux
```bash
source .venv/bin/activate
```
- Windows
```powershell
.venv\Scripts\Activate.ps1
```

## 安装包
```bash
uv add torch==2.9.0+cu130 torchvision==0.24.0 torchaudio==2.9.0 --default-index https://download.pytorch.org/whl/cu130
```
## 测试
```python
import torch

def check_torch_cuda():
    print("✅ PyTorch 版本:", torch.__version__)
    print("✅ PyTorch 内置 CUDA 版本:", torch.version.cuda)
    print("✅ PyTorch 内置 cuDNN 版本:", torch.backends.cudnn.version())

    if torch.cuda.is_available():
        print("\n🔥 GPU 加速状态：已激活")
        print("• 当前显卡型号:", torch.cuda.get_device_name(0))
        print("• 可用 GPU 数量:", torch.cuda.device_count())
        print("• 显存总容量: {:.2f} GB".format(
            torch.cuda.get_device_properties(0).total_memory / 1e9))
    else:
        print("\n❌ GPU 加速状态：未检测到可用显卡")

if __name__ == "__main__":
    check_torch_cuda()
```

## 退出隔离环境
```bash
deactivate
```

## 复现环境
```bash
uv sync
```