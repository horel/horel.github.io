---
title: "Conda的安装与配置"
comment: false
weight: 0
date: 2025-11-03T21:58:40+08:00
# 由 enableGitInfo 替代
# lastmod: 3000-11-11
# draft: false
# math: true
# featuredImage: ""
# featuredImagePreview: ""
# keywords: [""]
categories: ["环境"]
tags:
  - 环境
---

## Conda安装
使用winget安装即可
```powershell
winget install -i Anaconda.Miniconda3
```
由于更新频繁，完成后可以锁住版本
```powershell
winget pin add --id=Anaconda.Miniconda3
```

## Conda配置
### 安装时选项
- [x] Create start menu shortcuts (supported packages only).
- [ ] Add Miniconda3 to my PATH environment variable
- [x] Register Miniconda3 as my default Python 3.13
- [x] Clear the package cache upon completion
### 设置环境变量
移到最前面避免被windows自带python影响
- C:\Users\horel\miniconda3
- C:\Users\horel\miniconda3\Scripts
### 修改powershell配置
新建profile.ps1

> 设置懒加载，只有当运行conda命令时才hook
```powershell
#region conda initialize (deferred via proxy)
$condaExe = 'C:\Users\horel\miniconda3\Scripts\conda.exe'

if (Test-Path $condaExe) {

    function Invoke-CondaInit {
        param(
            [Parameter(ValueFromRemainingArguments=$true)]
            $Args
        )

        if (-not (Get-Variable -Name '__CondaInitialized' -Scope Script -ErrorAction SilentlyContinue)) {
            Set-Variable -Name '__CondaInitialized' -Value $true -Scope Script

            try {
                $hook = & $condaExe 'shell.powershell' 'hook'
                if ($LASTEXITCODE -ne 0 -or -not $hook) {
                    throw "conda hook failed"
                }

                $hook | Out-String | Where-Object { $_ } | Invoke-Expression

                Set-Item -Path Function:conda -Value {
                    param(
                        [Parameter(ValueFromRemainingArguments=$true)]
                        $Args
                    )
                    & $condaExe @Args
                }
            }
            catch {
                Write-Verbose "Conda lazy init failed: $_"
                Set-Item -Path Function:conda -Value {
                    param(
                        [Parameter(ValueFromRemainingArguments=$true)]
                        $Args
                    )
                    & $condaExe @Args
                }
            }
        }

        & conda @Args
    }

    Set-Item -Path Function:conda -Value {
        param(
            [Parameter(ValueFromRemainingArguments=$true)]
            $Args
        )
        Invoke-CondaInit @Args
    }
}
#endregion

Set-Alias -Name py -Value python
```
### 设置提示符
使默认环境提示符不显示
```powershell
conda config --set changeps1 false
```
修改oh-my-posh主题, 添加到rprompt
```json
        {
          "type": "python",
          "style": "plain",
          "foreground": "#B8860B",
          "template": "\ue235 {{ .Venv }}",
          "properties": {
            "fetch_virtual_env": true,
            "display_mode": "environment",
            "home_enabled": false
          }
        }
```

### 可选
如果要使base环境默认不激活
```powershell
conda config --set auto_activate false
```