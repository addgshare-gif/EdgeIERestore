###############################################################################
# Edge IE Mode Manager (Auto-Update Edition)
# Version: 1.0.0
###############################################################################

###############################################
# Auto Update (Fixed for EdgeIERestore repo)
###############################################

$LocalVersion = "1.0.0"

# 正确的仓库：EdgeIERestore
$VersionURL = "https://raw.githubusercontent.com/addgshare-gif/EdgeIERestore/main/version.txt"
$UpdateURL  = "https://raw.githubusercontent.com/addgshare-gif/EdgeIERestore/main/EdgeIEModeManager.ps1"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $RemoteVersion = (Invoke-WebRequest $VersionURL -UseBasicParsing -TimeoutSec 5).Content.Trim()

    if ([version]$RemoteVersion -gt [version]$LocalVersion) {

        Write-Host "New version $RemoteVersion available. Updating..."

        $TempFile = "$env:TEMP\EdgeIEModeManager_Update.ps1"

        # 下载最新脚本
        Invoke-WebRequest -Uri $UpdateURL -OutFile $TempFile -UseBasicParsing

        # 覆盖旧脚本，自启动
        Start-Process "powershell.exe" "-ExecutionPolicy Bypass -File `"$TempFile`""
        exit
    }
}
catch {
    Write-Host "Update check failed: $($_.Exception.Message)"
}

# -----------------------------
# TLS Fix
# -----------------------------
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# -----------------------------
# Single Instance (Mutex)
# -----------------------------
$mutexName = "Global\EdgeIEModeManager_12345"
$mutex = New-Object System.Threading.Mutex($false, $mutexName, [ref]$createdNew)
if (-not $createdNew) { exit }

# -----------------------------
# Admin Check
# -----------------------------
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        "Please run this script as Administrator.",
        "Administrator Required",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    exit
}

# -----------------------------
# Load Windows Forms
# -----------------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# -----------------------------
# Language & Text
# -----------------------------
$Global:Lang = "en"    # default EN

$T = @{
    Title            = @{ en="Edge Policy & IE Mode Manager"; zh="Edge 策略 & IE 模式管理" }
    InstallADMX      = @{ en="Install Edge Templates"; zh="安装 Edge 模板" }
    EnableIE         = @{ en="Enable IE Mode"; zh="启用 IE 模式" }
    DisableIE        = @{ en="Disable IE Mode"; zh="禁用 IE 模式" }
    Apply            = @{ en="Apply IE Mode"; zh="应用 IE 模式" }
    GPUpdate         = @{ en="Run GPUpdate"; zh="更新组策略" }
    RestartEdge      = @{ en="Restart Edge"; zh="重启 Edge" }
    SwitchLang       = @{ en="中文"; zh="EN" }
    ADMXDone         = @{ en="Templates installed."; zh="模板已安装。" }
    IEModeOn         = @{ en="IE Mode enabled."; zh="IE 模式已启用。" }
    IEModeOff        = @{ en="IE Mode disabled."; zh="IE 模式已禁用。" }
}

function TXT($key){ return $T[$key][$Global:Lang] }

# -----------------------------
# Auto-detect 7-Zip
# -----------------------------
$SevenZipCandidates = @(
    "C:\Program Files\7-Zip\7z.exe",
    "C:\Program Files (x86)\7-Zip\7z.exe",
    "$env:ProgramFiles\7-Zip\7z.exe",
    "$env:ProgramW6432\7-Zip\7z.exe",
    (Get-Command 7z.exe -ErrorAction SilentlyContinue)?.Source
)

$SevenZip = $SevenZipCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $SevenZip) {
    [System.Windows.Forms.MessageBox]::Show("7-Zip not found.","Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}

# -----------------------------
# Form GUI
# -----------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = TXT "Title"
$form.Size = New-Object System.Drawing.Size(460, 300)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text = TXT "InstallADMX"
$btnInstall.Location = "20,20"
$btnInstall.Size = "180,35"
$form.Controls.Add($btnInstall)

$rbEnable = New-Object System.Windows.Forms.RadioButton
$rbEnable.Text = TXT "EnableIE"
$rbEnable.Location = "20,80"
$rbEnable.Checked = $true
$form.Controls.Add($rbEnable)

$rbDisable = New-Object System.Windows.Forms.RadioButton
$rbDisable.Text = TXT "DisableIE"
$rbDisable.Location = "20,110"
$form.Controls.Add($rbDisable)

$btnApply = New-Object System.Windows.Forms.Button
$btnApply.Text = TXT "Apply"
$btnApply.Location = "20,150"
$btnApply.Size = "120,30"
$form.Controls.Add($btnApply)

$btnGP = New-Object System.Windows.Forms.Button
$btnGP.Text = TXT "GPUpdate"
$btnGP.Location = "160,150"
$btnGP.Size = "120,30"
$form.Controls.Add($btnGP)

$btnRestart = New-Object System.Windows.Forms.Button
$btnRestart.Text = TXT "RestartEdge"
$btnRestart.Location = "300,150"
$btnRestart.Size = "120,30"
$form.Controls.Add($btnRestart)

$btnLang = New-Object System.Windows.Forms.Button
$btnLang.Text = TXT "SwitchLang"
$btnLang.Location = "380,10"
$btnLang.Size = "60,28"
$form.Controls.Add($btnLang)

$labelStatus = New-Object System.Windows.Forms.Label
$labelStatus.AutoSize = $true
$labelStatus.Location = "20,200"
$form.Controls.Add($labelStatus)

# -----------------------------
# Language Switch
# -----------------------------
$btnLang.Add_Click({
    $Global:Lang = if ($Global:Lang -eq "en") { "zh" } else { "en" }

    $form.Text = TXT "Title"
    $btnInstall.Text = TXT "InstallADMX"
    $rbEnable.Text = TXT "EnableIE"
    $rbDisable.Text = TXT "DisableIE"
    $btnApply.Text = TXT "Apply"
    $btnGP.Text = TXT "GPUpdate"
    $btnRestart.Text = TXT "RestartEdge"
    $btnLang.Text = TXT "SwitchLang"
})

# -----------------------------
# Install Edge ADMX
# -----------------------------
$btnInstall.Add_Click({
    $labelStatus.Text = "Downloading templates..."
    try {
        $latestPage = Invoke-WebRequest "https://www.microsoft.com/en-us/edge/business/download" -UseBasicParsing
        $match = ($latestPage.Links | Where-Object { $_.href -match "MicrosoftEdgePolicyTemplates" }).href
        if (-not $match) { throw "Download link not found." }

        $url = ("https://www.microsoft.com" + $match)
        $tmp = "$env:TEMP\EdgeADMX"
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $tmp | Out-Null
        $cab = "$tmp\edge.cab"
        Invoke-WebRequest -Uri $url -OutFile $cab -UseBasicParsing

        & $SevenZip x $cab "-o$tmp" -y | Out-Null
        $zip = Get-ChildItem $tmp "*.zip" -Recurse | Select-Object -First 1
        & $SevenZip x $zip.FullName "-o$tmp" -y | Out-Null

        $admx = "$tmp\windows\admx"
        Copy-Item "$admx\*.admx" -Destination "$env:WINDIR\PolicyDefinitions" -Force
        Copy-Item "$admx\en-US\*.adml" -Destination "$env:WINDIR\PolicyDefinitions\en-US" -Force

        $labelStatus.Text = TXT "ADMXDone"
    }
    catch {
        $labelStatus.Text = "Error: $($_.Exception.Message)"
    }
})

# -----------------------------
# Enterprise SiteList
# -----------------------------
$SiteListPath = "C:\Windows\edge_ie_sitelist.xml"
function Write-SiteList {
@"
<?xml version="1.0" encoding="utf-8"?>
<site-list version="1">
  <site url="http://intranet">
    <compat-mode>IE11</compat-mode>
  </site>
</site-list>
"@ | Set-Content -Encoding UTF8 -Path $SiteListPath
}

# -----------------------------
# Apply IE Mode
# -----------------------------
$btnApply.Add_Click({
    $edgeKey = "HKLM:\Software\Policies\Microsoft\Edge"
    if (-not (Test-Path $edgeKey)) { New-Item $edgeKey -Force | Out-Null }
    Write-SiteList

    if ($rbEnable.Checked) {
        Set-ItemProperty $edgeKey InternetExplorerIntegrationLevel 1
        Set-ItemProperty $edgeKey InternetExplorerIntegrationSiteList $SiteListPath
        $labelStatus.Text = TXT "IEModeOn"
    }
    else {
        Set-ItemProperty $edgeKey InternetExplorerIntegrationLevel 0
        Remove-ItemProperty $edgeKey InternetExplorerIntegrationSiteList -ErrorAction SilentlyContinue
        $labelStatus.Text = TXT "IEModeOff"
    }
})

# -----------------------------
# GPUpdate
# -----------------------------
$btnGP.Add_Click({
    Start-Process "gpupdate.exe" "/force" -Wait
    $labelStatus.Text = "Group policy updated."
})

# -----------------------------
# Restart Edge
# -----------------------------
$btnRestart.Add_Click({
    Get-Process "msedge" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Process "msedge.exe"
    $labelStatus.Text = "Edge restarted."
})

# -----------------------------
# Run Form
# -----------------------------
$form.Topmost = $false
$form.Add_Shown({ $form.Activate() })
$form.ShowDialog() | Out-Null


