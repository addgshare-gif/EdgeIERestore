# Update.psm1
# 自动更新模块 for EdgeIERestore

function Get-LatestVersion {
    # 获取 GitHub 最新 Release 版本号
    $repo = "addgshare-gif/EdgeIERestore"
    $url = "https://api.github.com/repos/$repo/releases/latest"

    try {
        $resp = Invoke-RestMethod -Uri $url -UseBasicParsing
        return $resp.tag_name
    }
    catch {
        Write-Error "无法获取最新版本: $_"
        return $null
    }
}

function Get-LocalVersion {
    param(
        [string]$VersionFile = "$PSScriptRoot\version.txt"
    )

    if (Test-Path $VersionFile) {
        return Get-Content $VersionFile -Raw
    } else {
        return "0.0.0"
    }
}

function Download-LatestExe {
    param(
        [string]$DownloadDir = "$env:TEMP\EdgeIERestore_Update"
    )

    if (-Not (Test-Path $DownloadDir)) {
        New-Item -ItemType Directory -Path $DownloadDir | Out-Null
    }

    $repo = "addgshare-gif/EdgeIERestore"
    $fileName = "EdgeIEModeRestorer.exe"

    $url = "https://github.com/$repo/releases/latest/download/$fileName"
    $dest = Join-Path $DownloadDir $fileName

    Write-Host "Downloading latest version..."
    Invoke-WebRequest -Uri $url -OutFile $dest

    return $dest
}

function Update-Application {
    param(
        [string]$ExePath = "$PSScriptRoot\EdgeIEModeRestorer.exe",
        [string]$VersionFile = "$PSScriptRoot\version.txt"
    )

    $latest = Get-LatestVersion
    if (-not $latest) { return }

    $local = Get-LocalVersion -VersionFile $VersionFile

    if ($latest -eq $local) {
        [System.Windows.Forms.MessageBox]::Show("已是最新版本！", "更新")
        return
    }

    $newExe = Download-LatestExe

    # 等待用户确认替换
    $res = [System.Windows.Forms.MessageBox]::Show("发现新版本 $latest, 是否更新？","更新提示","YesNo")
    if ($res -ne "Yes") { return }

    # 复制到当前目录覆盖旧 exe
    $backup = "$ExePath.bak"
    Copy-Item $ExePath $backup -Force

    try {
        Copy-Item $newExe $ExePath -Force
        Set-Content -Path $VersionFile -Value $latest
        [System.Windows.Forms.MessageBox]::Show("更新完成，正在重启程序...", "更新成功")
        
        # 启动新版本
        Start-Process $ExePath
        # 关闭当前 PowerShell
        exit
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("更新失败！请手动更新。`n$_","更新失败")
        # 恢复备份
        Copy-Item $backup $ExePath -Force
    }
}
