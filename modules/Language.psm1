$Global:Lang = "en"

$LanguageTable = @{
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
    GPUpdated        = @{ en="Group policy updated."; zh="组策略已更新。" }
    EdgeRestarted    = @{ en="Edge restarted."; zh="Edge 已重启。" }
}

function Set-Lang {
    param([string]$NewLang)

    if ($NewLang -in @("en","zh")) {
        $Global:Lang = $NewLang
    }
}

function TXT {
    param([string]$Key)
    return $LanguageTable[$Key][$Global:Lang]
}

Export-ModuleMember -Function TXT, Set-Lang
