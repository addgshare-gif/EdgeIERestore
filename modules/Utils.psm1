function Require-Admin {
    If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent())
        .IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {

        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            "Please run this script as Administrator.",
            "Administrator Required",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        exit
    }
}

function Ensure-SingleInstance {
    $mutexName = "Global\EdgeIEModeManager_Mutex"
    $mutex = New-Object System.Threading.Mutex($false, $mutexName, [ref]$createdNew)
    if (-not $createdNew) { exit }
}

Export-ModuleMember -Function Require-Admin, Ensure-SingleInstance
