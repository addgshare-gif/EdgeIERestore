function Invoke-AutoUpdate {
    param(
        [Parameter(Mandatory=$true)]
        $Config
    )

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $RepoRoot = $Config.repo
        $LocalVersion = $Config.version

        $RemoteVersionURL = "$RepoRoot/version.txt"
        $RemoteVersion = (Invoke-WebRequest $RemoteVersionURL -UseBasicParsing).Content.Trim()

        if ([version]$RemoteVersion -le [version]$LocalVersion) {
            return  # no update
        }

        Write-Host "New version $RemoteVersion available. Updating..."

        # 临时更新目录
        $TempDir = Join-Path $env:TEMP "EdgeIERestore_Update"
        Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $TempDir | Out-Null

        foreach ($file in $Config.update_targets) {
            $url = "$RepoRoot/$file"
            $target = Join-Path $TempDir $file

            $targetDir = Split-Path $target
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }

            Invoke-WebRequest -Uri $url -OutFile $target -UseBasicParsing
        }

        # 复制更新文件到当前目录
        $ProjectRoot = Split-Path -Parent $PSScriptRoot
        Copy-Item "$TempDir\*" $ProjectRoot -Recurse -Force

        # 重启脚本
        $ThisScript = Join-Path $ProjectRoot "EdgeIEModeManager.ps1"
        Start-Process "powershell.exe" "-ExecutionPolicy Bypass -File `"$ThisScript`""

        exit
    }
    catch {
        Write-Host "Auto update failed: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function Invoke-AutoUpdate
