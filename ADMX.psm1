function Get-7ZipPath {
    $candidates = @(
        "C:\Program Files\7-Zip\7z.exe",
        "C:\Program Files (x86)\7-Zip\7z.exe",
        "$env:ProgramFiles\7-Zip\7z.exe",
        "$env:ProgramW6432\7-Zip\7z.exe",
        (Get-Command 7z.exe -ErrorAction SilentlyContinue)?.Source
    )

    foreach ($p in $candidates) {
        if ($p -and (Test-Path $p)) { return $p }
    }

    throw "7-Zip not found."
}

function Install-EdgeADMX {
    param($StatusLabel)

    try {
        $StatusLabel.Text = "Downloading templates..."

        # 微软 ADMX 模板的固定下载源（官方 CDN）
        $DownloadPage = Invoke-WebRequest "https://edgeenterprise.microsoft.com/download" -UseBasicParsing

        # 从页面中提取真实下载链接（不依赖 class，而是匹配 ZIP 名称）
        $match = ($DownloadPage.Links | Where-Object { $_.href -match "MicrosoftEdgePolicyTemplates" }).href
        if (-not $match) { throw "Cannot locate ADMX download URL." }

        $url = "https://edgeenterprise.microsoft.com$match"

        # 临时目录
        $tmp = "$env:TEMP\EdgeADMX"
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $tmp | Out-Null

        $cab = "$tmp\edge.cab"
        Invoke-WebRequest -Uri $url -OutFile $cab -UseBasicParsing

        $SevenZip = Get-7ZipPath

        # 解 CAB
        & $SevenZip x $cab "-o$tmp" -y | Out-Null

        # 找并解 ZIP
        $zip = Get-ChildItem $tmp "*.zip" -Recurse | Select-Object -First 1
        & $SevenZip x $zip.FullName "-o$tmp" -y | Out-Null

        $admx = "$tmp\windows\admx"

        Copy-Item "$admx\*.admx" -Destination "$env:WINDIR\PolicyDefinitions" -Force
        Copy-Item "$admx\en-US\*.adml" -Destination "$env:WINDIR\PolicyDefinitions\en-US" -Force

        $StatusLabel.Text = (TXT "ADMXDone")
    }
    catch {
        $StatusLabel.Text = "ADMX Error: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function Install-EdgeADMX
