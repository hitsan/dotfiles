# Windows settings for capella. Run manually; idempotent.
# Keep this file ASCII-only: Windows PowerShell 5.1 misreads UTF-8 without BOM.

function Set-Reg($Path, $Name, $Value, $Type = 'DWord') {
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
}

$adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-Reg $adv HideFileExt 0
Set-Reg $adv Hidden 1
Set-Reg $adv ShowTaskViewButton 0
Set-Reg $adv TaskbarDa 0
Set-Reg $adv TaskbarMn 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' SearchboxTaskbarMode 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' AppsUseLightTheme 0
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' Enabled 0

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    # CapsLock -> Left Ctrl (requires reboot)
    [byte[]]$map = 0,0,0,0, 0,0,0,0, 2,0,0,0, 0x1d,0,0x3a,0, 0,0,0,0
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout' 'Scancode Map' $map Binary
} else {
    Write-Warning 'Not running as administrator: skipped HKLM settings (CapsLock -> Ctrl).'
}

Write-Host 'Done. Sign out (or restart Explorer) to apply; reboot for keyboard remap.'
