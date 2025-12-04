# =====================================================================
# Edge IE Mode Manager (FINAL VERSION + Exit Button Integrated)
# =====================================================================

# -----------------------------
# Run as Administrator
# -----------------------------
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("⚠️ 请以管理员身份运行此脚本。","管理员权限",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)
    exit
}

# -----------------------------
# Prevent multiple instances
# -----------------------------
$procName = [System.IO.Path]::GetFileNameWithoutExtension([System.Diagnostics.Process]::GetCurrentProcess().ProcessName)
$alreadyRunning = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -eq $procName -and $_.Id -ne $PID }
if ($alreadyRunning) { exit }

# -----------------------------
# Load UI libs
# -----------------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# -----------------------------
# Version (Online Fetch)
# -----------------------------
$Global:VersionURL = "https://raw.githubusercontent.com/addgshare-gif/EdgeIERestore/main/version.txt"
$Global:InstallerURL = "https://raw.githubusercontent.com/addgshare-gif/EdgeIERestore/main/EdgeIEModeRestorer.exe"
$Global:InstallerName = "EdgeIEManager_Setup.exe"
$Global:ScriptURL  = "https://raw.githubusercontent.com/addgshare-gif/EdgeIERestore/main/EdgeIEModeManager.ps1"
$Global:LocalScriptPath = $MyInvocation.MyCommand.Path

try {
    $Global:CurrentVersion = (Invoke-WebRequest -Uri $Global:VersionURL -UseBasicParsing).Content.Trim()
} catch {
    $Global:CurrentVersion = "Unknown"
}

# -----------------------------
# Text dictionary
# -----------------------------
$TextDict = @{
"FormTitle"=@{"zh"="Edge 策略 & IE 模式管理";"en"="Edge Policy & IE Mode Manager"}
"ProgressLabel"=@{"zh"="点击'安装模板'以下载并安装 Microsoft Edge 策略模板";"en"="Click 'Install Templates' to download and install Edge policy templates."}
"IELabel"=@{"zh"="选择要应用的 IE 模式设置";"en"="Select an IE Mode option"}

"InstallTemplates"=@{"zh"="安装模板";"en"="Install Templates"}
"EnableIEMode"=@{"zh"="启用 IE 模式";"en"="Enable IE Mode"}
"DisableIEMode"=@{"zh"="禁用 IE 模式";"en"="Disable IE Mode"}
"ApplyIEMode"=@{"zh"="应用 IE 模式";"en"="Apply IE Mode"}

"GPUpdate"=@{"zh"="更新组策略";"en"="Run GPUpdate"}
"RestartEdge"=@{"zh"="重启 Edge";"en"="Restart Edge"}
"SwitchLang"=@{"zh"="EN";"en"="CN"}

"SevenZipMissing"=@{"zh"="❌ 未找到 7-Zip，请安装 7-Zip 或更新路径。";"en"="❌ 7-Zip not found."}
"TemplatesSuccess"=@{"zh"="✅ 模板安装成功！";"en"="Templates installed successfully."}

"Success"=@{"zh"="成功";"en"="Success"}
"IEModeEnabled"=@{"zh"="IE 模式已启用";"en"="IE Mode ENABLED"}
"IEModeDisabled"=@{"zh"="IE 模式已禁用";"en"="IE Mode DISABLED"}
"GPUpdateSuccess"=@{"zh"="组策略已更新";"en"="Group Policy updated"}
"RestartEdgeSuccess"=@{"zh"="Edge 已重启";"en"="Edge restarted"}

"CheckUpdate"=@{"zh"="检查更新";"en"="Check Update"}
"UpdateTitle"=@{"zh"="检查更新";"en"="Check Update"}
"UpdateAvailable"=@{"zh"="发现新版本: {0}`n当前版本: {1}";"en"="New version: {0}`nCurrent: {1}"}
"UpToDate"=@{"zh"="已是最新版本: {0}";"en"="You are using the latest version: {0}"}
"UpdateError"=@{"zh"="检查更新失败:`n{0}";"en"="Update check failed:`n{0}"}

"AboutVersion"=@{"zh"="关于版本";"en"="About"}
"AboutVersionInfo"=@{"zh"="Edge IE Mode Manager`n版本: {0}`n作者: addgshare-gif";"en"="Edge IE Mode Manager`nVersion: {0}`nAuthor: addgshare-gif"}

"Exit"=@{"zh"="退出";"en"="Exit"}
}

$Global:CurrentLang="zh"
function Get-Text($key){ return $TextDict[$key][$Global:CurrentLang] }

# -----------------------------
# GUI
# -----------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = Get-Text "FormTitle"
$form.Size = New-Object System.Drawing.Size(520,340)
$form.StartPosition="CenterScreen"
$form.FormBorderStyle="FixedDialog"
$form.MaximizeBox=$false

$label = New-Object System.Windows.Forms.Label
$label.Location=New-Object System.Drawing.Point(20,20)
$label.AutoSize=$true
$label.Text=Get-Text "ProgressLabel"
$form.Controls.Add($label)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location=New-Object System.Drawing.Point(20,45)
$progress.Size=New-Object System.Drawing.Size(460,18)
$progress.Style="Marquee"
$progress.Visible=$false
$form.Controls.Add($progress)

$ieLabel = New-Object System.Windows.Forms.Label
$ieLabel.Text=Get-Text "IELabel"
$ieLabel.Size=New-Object System.Drawing.Size(460,20)
$ieLabel.Location=New-Object System.Drawing.Point(20,120)
$form.Controls.Add($ieLabel)

$sevenZip="C:\Program Files\7-Zip\7z.exe"
if (!(Test-Path $sevenZip)) {
    [System.Windows.Forms.MessageBox]::Show((Get-Text "SevenZipMissing"),"7-Zip",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}

# -----------------------------
# Buttons
# -----------------------------
$installButton=New-Object System.Windows.Forms.Button
$installButton.Location=New-Object System.Drawing.Point(180,70)
$installButton.Size=New-Object System.Drawing.Size(140,35)
$installButton.Text=Get-Text "InstallTemplates"
$form.Controls.Add($installButton)

$enableRadio=New-Object System.Windows.Forms.RadioButton
$enableRadio.Text=Get-Text "EnableIEMode"
$enableRadio.Location=New-Object System.Drawing.Point(50,145)
$enableRadio.Checked=$true
$form.Controls.Add($enableRadio)

$disableRadio=New-Object System.Windows.Forms.RadioButton
$disableRadio.Text=Get-Text "DisableIEMode"
$disableRadio.Location=New-Object System.Drawing.Point(50,170)
$disableRadio.AutoSize=$True
$form.Controls.Add($disableRadio)

$applyButton=New-Object System.Windows.Forms.Button
$applyButton.Text=Get-Text "ApplyIEMode"
$applyButton.Location=New-Object System.Drawing.Point(21,210)
$applyButton.Size=New-Object System.Drawing.Size(140,30)
$form.Controls.Add($applyButton)

$restartButton=New-Object System.Windows.Forms.Button
$restartButton.Text=Get-Text "RestartEdge"
$restartButton.Location=New-Object System.Drawing.Point(182,210)
$restartButton.Size=New-Object System.Drawing.Size(140,30)
$form.Controls.Add($restartButton)

$gpupdateButton=New-Object System.Windows.Forms.Button
$gpupdateButton.Text=Get-Text "GPUpdate"
$gpupdateButton.Location=New-Object System.Drawing.Point(343,210)
$gpupdateButton.Size=New-Object System.Drawing.Size(140,30)
$form.Controls.Add($gpupdateButton)

$switchLangButton=New-Object System.Windows.Forms.Button
$switchLangButton.Text=Get-Text "SwitchLang"
$switchLangButton.Location=New-Object System.Drawing.Point(430,10)
$switchLangButton.Size=New-Object System.Drawing.Size(50,30)
$form.Controls.Add($switchLangButton)

$updateButton=New-Object System.Windows.Forms.Button
$updateButton.Text=Get-Text "CheckUpdate"
$updateButton.Location=New-Object System.Drawing.Point(182,250)
$updateButton.Size=New-Object System.Drawing.Size(140,30)
$form.Controls.Add($updateButton)

$aboutButton=New-Object System.Windows.Forms.Button
$aboutButton.Text=Get-Text "AboutVersion"
$aboutButton.Location=New-Object System.Drawing.Point(343,250)
$aboutButton.Size=New-Object System.Drawing.Size(140,30)
$form.Controls.Add($aboutButton)

# EXIT 按钮
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = Get-Text "Exit"
$exitButton.Location = New-Object System.Drawing.Point(21,250)
$exitButton.Size = New-Object System.Drawing.Size(140,30)
$form.Controls.Add($exitButton)

# -----------------------------
# Language Switch
# -----------------------------
$switchLangButton.Add_Click({
    if ($Global:CurrentLang -eq "zh") { $Global:CurrentLang="en" } else { $Global:CurrentLang="zh" }
    $form.Text=Get-Text "FormTitle"
    $label.Text=Get-Text "ProgressLabel"
    $ieLabel.Text=Get-Text "IELabel"
    $installButton.Text=Get-Text "InstallTemplates"
    $enableRadio.Text=Get-Text "EnableIEMode"
    $disableRadio.Text=Get-Text "DisableIEMode"
    $applyButton.Text=Get-Text "ApplyIEMode"
    $gpupdateButton.Text=Get-Text "GPUpdate"
    $restartButton.Text=Get-Text "RestartEdge"
    $switchLangButton.Text=Get-Text "SwitchLang"
    $updateButton.Text=Get-Text "CheckUpdate"
    $aboutButton.Text=Get-Text "AboutVersion"
    $exitButton.Text = Get-Text "Exit"
})

# -----------------------------
# Install Templates
# -----------------------------
$installButton.Add_Click({
    $progress.Visible=$true
    try{
        $url="https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/17f8b07b-6112-420d-ad37-61d17e574c4b/MicrosoftEdgePolicyTemplates.cab"
        $temp="$env:TEMP\EdgePolicyTemplates"
        $cab="$temp\temp.cab"
        $pd="$env:WINDIR\PolicyDefinitions"

        if(!(Test-Path $temp)){New-Item -ItemType Directory -Path $temp|Out-Null}
        Invoke-WebRequest -Uri $url -OutFile $cab -UseBasicParsing
        & $sevenZip x $cab -o"$temp" -y |Out-Null
        $zip=Get-ChildItem -Path $temp -Filter "*.zip" -Recurse|Select-Object -First 1
        & $sevenZip x $zip.FullName -o"$temp" -y |Out-Null

        Copy-Item -Path "$temp\windows\admx\*.admx" -Destination $pd -Force
        Copy-Item -Path "$temp\windows\admx\en-US\*.adml" -Destination "$pd\en-US" -Force

        Remove-Item -Path $temp -Recurse -Force -ErrorAction SilentlyContinue
        $label.Text=Get-Text "TemplatesSuccess"
    }catch{ $label.Text="❌ Error: $($_.Exception.Message)"}
    $progress.Visible=$false
})

# -----------------------------
# IE Mode Apply
# -----------------------------
$EnterpriseModeListURL="https://iemode/sites.xml"
$applyButton.Add_Click({
    $edgeKey="HKLM:\Software\Policies\Microsoft\Edge"
    if(!(Test-Path $edgeKey)){New-Item $edgeKey -Force|Out-Null}

    if($enableRadio.Checked){
        Set-ItemProperty -Path $edgeKey -Name "InternetExplorerIntegrationLevel" -Value 1 -Type DWord
        Set-ItemProperty -Path $edgeKey -Name "InternetExplorerIntegrationSiteList" -Value $EnterpriseModeListURL
        [System.Windows.Forms.MessageBox]::Show((Get-Text "IEModeEnabled"),(Get-Text "Success"),[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        Set-ItemProperty -Path $edgeKey -Name "InternetExplorerIntegrationLevel" -Value 0 -Type DWord
        Remove-ItemProperty -Path $edgeKey -Name "InternetExplorerIntegrationSiteList" -ErrorAction SilentlyContinue
        [System.Windows.Forms.MessageBox]::Show((Get-Text "IEModeDisabled"),(Get-Text "Success"),[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

# -----------------------------
# GPUpdate
# -----------------------------
$gpupdateButton.Add_Click({
    Start-Process "gpupdate.exe" -ArgumentList "/force" -Wait
    [System.Windows.Forms.MessageBox]::Show((Get-Text "GPUpdateSuccess"),(Get-Text "Success"),[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
})

# -----------------------------
# Restart Edge
# -----------------------------
$restartButton.Add_Click({
    Get-Process "msedge" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Process "msedge.exe"
    [System.Windows.Forms.MessageBox]::Show((Get-Text "RestartEdgeSuccess"),(Get-Text "Success"),[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
})

# -----------------------------
# Check Update + External Updater
# -----------------------------
$updateButton.Add_Click({
    try{
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $latest = (Invoke-RestMethod -Uri $Global:VersionURL).Trim()

        if($latest -ne $Global:CurrentVersion){
            $msg=[System.Windows.Forms.MessageBox]::Show(
                [string]::Format((Get-Text "UpdateAvailable"),$latest,$Global:CurrentVersion),
                (Get-Text "UpdateTitle"),[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question
            )

            if ($msg -eq [System.Windows.Forms.DialogResult]::Yes) {
                $installerPath = "$env:TEMP\$($Global:InstallerName)"
                Invoke-WebRequest -Uri $Global:InstallerURL -OutFile $installerPath -UseBasicParsing

                Start-Process $installerPath "/silent /verysilent /norestart" -Wait

                $ps = (Get-Process -Id $PID).Path
                Start-Process $ps "-ExecutionPolicy Bypass -File `"$($Global:LocalScriptPath)`""
                $form.Close()
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show(
                [string]::Format((Get-Text "UpToDate"),$Global:CurrentVersion),
                (Get-Text "UpdateTitle"),[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
        }
    }catch{
        [System.Windows.Forms.MessageBox]::Show(
            [string]::Format((Get-Text "UpdateError"), $_.Exception.Message),
            (Get-Text "UpdateTitle"),[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# -----------------------------
# Exit Button
# -----------------------------
$exitButton.Add_Click({
    $form.Close()
})

# -----------------------------
# About
# -----------------------------
$aboutButton.Add_Click({
    [System.Windows.Forms.MessageBox]::Show(
        [string]::Format((Get-Text "AboutVersionInfo"),$Global:CurrentVersion),
        (Get-Text "AboutVersion"),
        [System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
})

# -----------------------------
# Show Window
# -----------------------------
$form.Topmost=$false
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
