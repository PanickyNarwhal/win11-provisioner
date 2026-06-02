
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as an Administrator."
    Exit
}
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ConfigFile = Join-Path $ScriptDir "config.json"

if (-not (Test-Path $ConfigFile)) {
    Write-Error "Configuration file (config.json) not found!"
    Exit
}

$Config = Get-Content -Raw $ConfigFile | ConvertFrom-Json

$RandomID = Get-Random -Minimum 100 -Maximum 999
$NewName = "$($Config.ComputerNamePrefix)$RandomID"
Write-Output "Renaming computer to $NewName..."
Rename-Computer -NewName $NewName -Force
Write-Output "Initializing WinGet environment..."
& winget source reset --force
Write-Output "Starting software deployment..."
foreach ($AppID in $Config.AppsToInstall) {
    Write-Output "Installing: $AppID"
    & winget install --id $AppID --silent --accept-package-agreements --accept-source-agreements --scope machine
}

Write-Output "Removing pre-installed bloatware..."
foreach ($Package in $Config.BloatwareToRemove) {
    Write-Output "Removing: $Package"
    Get-AppxPackage -Name $Package -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
}

Write-Output "Provisioning complete! Rebooting in 10 seconds..."
Start-Sleep -Seconds 10
Restart-Computer -Force