Import-Module "$PSScriptRoot\Language.psm1" -Force
Import-Module "$PSScriptRoot\ADMX.psm1" -Force
Import-Module "$PSScriptRoot\IEManager.psm1" -Force

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Start-EdgeManagerUI {
    param($Config)

    $form              = New-Object System.Windows.Forms.Form
    $form.Text         = TXT "Title"
    $form.Size         = New-Object System.Drawing.Size(460, 300)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox  = $false
    $form.TopMost      = $false

    # Install ADMX
    $btnInstall = New-Object System.Windows.Forms.Button
    $btnInstall.Text = TXT "InstallADMX"
    $btnInstall.Location = "20,20"
    $btnInstall.Size = "180,35"
    $form.Controls.Add($btnInstall)

    # Radio buttons
    $rbEnable = New-Object System.Windows.Forms.RadioButton
    $rbEnable.Text = TXT "EnableIE"
    $rbEnable.Location = "20,80"
    $rbEnable.Checked = $true
    $form.Controls.Add($rbEnable)

    $rbDisable = New-Object System.Windows.Forms.RadioButton
    $rbDisable.Text = TXT "DisableIE"
    $rbDisable.Location = "20,110"
    $form.Controls.Add($rbDisable)

    # Apply button
    $btnApply = New-Object System.Windows.Forms.Button
    $btnApply.Text = TXT "Apply"
    $btnApply.Location = "20,150"
    $btnApply.Size = "120,30"
    $form.Controls.Add($btnApply)

    # GPUpdate
    $btnGP = New-Object System.Windows.Forms.Button
    $btnGP.Text = TXT "GPUpdate"
    $btnGP.Location = "160,150"
    $btnGP.Size = "120,30"
    $form.Controls.Add($btnGP)

    # Restart Edge
    $btnRestart = New-Object System.Windows.Forms.Button
    $btnRestart.Text = TXT "RestartEdge"
    $btnRestart.Location = "300,150"
    $btnRestart.Size = "120,30"
    $form.Controls.Add($btnRestart)

    # Switch Lang
    $btnLang = New-Object System.Windows.Forms.Button
    $btnLang.Text = TXT "SwitchLang"
    $btnLang.Location = "380,10"
    $btnLang.Size = "60,28"
    $form.Controls.Add($btnLang)

    # Status label
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.AutoSize = $true
    $lbl.Location = "20,200"
    $form.Controls.Add($lbl)

    #####################################################
    # Event bindings
    #####################################################

    # Language switch
    $btnLang.Add_Click({
        if ($Global:Lang -eq "en") { Set-Lang "zh" } else { Set-Lang "en" }

        # Refresh text
        $form.Text = TXT "Title"
        $btnInstall.Text = TXT "InstallADMX"
        $rbEnable.Text = TXT "EnableIE"
        $rbDisable.Text = TXT "DisableIE"
        $btnApply.Text = TXT "Apply"
        $btnGP.Text = TXT "GPUpdate"
        $btnRestart.Text = TXT "RestartEdge"
        $btnLang.Text = TXT "SwitchLang"
    })

    # ADMX install
    $btnInstall.Add_Click({
        Install-EdgeADMX -StatusLabel $lbl
    })

    # Apply IE mode
    $btnApply.Add_Click({
        if ($rbEnable.Checked) {
            Enable-IEMode
            $lbl.Text = TXT "IEModeOn"
        }
        else {
            Disable-IEMode
            $lbl.Text = TXT "IEModeOff"
        }
    })

    # GPUpdate
    $btnGP.Add_Click({
        Run-GPUpdate
        $lbl.Text = TXT "GPUpdated"
    })

    # Restart Edge
    $btnRestart.Add_Click({
        Restart-Edge
        $lbl.Text = TXT "EdgeRestarted"
    })

    $form.ShowDialog() | Out-Null
}

Export-ModuleMember -Function Start-EdgeManagerUI
