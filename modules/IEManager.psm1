function Write-SiteList {
    $SiteListPath = "C:\Windows\edge_ie_sitelist.xml"
@"
<?xml version="1.0" encoding="utf-8"?>
<site-list version="1">
  <site url="http://intranet">
    <compat-mode>IE11</compat-mode>
  </site>
</site-list>
"@ | Set-Content -Encoding UTF8 -Path $SiteListPath

    return $SiteListPath
}

function Enable-IEMode {
    $key = "HKLM:\Software\Policies\Microsoft\Edge"
    if (-not (Test-Path $key)) { New-Item $key -Force | Out-Null }

    $path = Write-SiteList
    Set-ItemProperty $key InternetExplorerIntegrationLevel 1
    Set-ItemProperty $key InternetExplorerIntegrationSiteList $path
}

function Disable-IEMode {
    $key = "HKLM:\Software\Policies\Microsoft\Edge"
    if (-not (Test-Path $key)) { return }

    Set-ItemProperty $key InternetExplorerIntegrationLevel 0
    Remove-ItemProperty $key InternetExplorerIntegrationSiteList -ErrorAction SilentlyContinue
}

function Run-GPUpdate {
    Start-Process "gpupdate.exe" "/force" -Wait
}

function Restart-Edge {
    Get-Process "msedge" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Process "msedge.exe"
}

Export-ModuleMember -Function Enable-IEMode,Disable-IEMode,Run-GPUpdate,Restart-Edge
