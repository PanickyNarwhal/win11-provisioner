#Requires -RunAsAdministrator

# ── Locate config.json robustly ──────────────────────────────────────────────
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }
$ConfigFile = Join-Path $ScriptDir "config.json"

if (-not (Test-Path $ConfigFile)) {
    $fallbacks = @(
        "C:\Windows\Provisioning\Packages",
        "C:\ProgramData\Microsoft\Windows\Provisioning"
    )
    foreach ($path in $fallbacks) {
        $candidate = Join-Path $path "config.json"
        if (Test-Path $candidate) { $ConfigFile = $candidate; break }
    }
}

if (-not (Test-Path $ConfigFile)) {
    Write-Error "config.json not found. Aborting."
    Exit 1
}

$Config = Get-Content -Raw $ConfigFile | ConvertFrom-Json

# ── Rename computer ───────────────────────────────────────────────────────────
$RandomID  = Get-Random -Minimum 100 -Maximum 999
$NewName   = "$($Config.ComputerNamePrefix)$RandomID"
Write-Output "Renaming computer to $NewName..."
Rename-Computer -NewName $NewName -Force -ErrorAction SilentlyContinue

# ── Bootstrap winget ──────────────────────────────────────────────────────────
Write-Output "Bootstrapping winget..."

$appInstaller = Get-AppxPackage -Name "Microsoft.DesktopAppInstaller" -AllUsers -ErrorAction SilentlyContinue
if (-not $appInstaller) {
    Write-Output "App Installer not found — installing from store bundle..."
    # This pulls the latest msixbundle from Microsoft
    $uri = "https://aka.ms/getwinget"
    $out = "$env:TEMP\AppInstaller.msixbundle"
    Invoke-WebRequest -Uri $uri -OutFile $out -UseBasicParsing
    Add-AppxPackage -Path $out
}

$wingetReady = $false
for ($i = 0; $i -lt 24; $i++) {
    try {
        $null = & winget --version 2>&1
        if ($LASTEXITCODE -eq 0) { $wingetReady = $true; break }
    } catch {}
    Write-Output "Waiting for winget... ($($i * 5)s)"
    Start-Sleep -Seconds 5
}

if (-not $wingetReady) {
    Write-Error "Winget never became ready. Aborting installs."
    Exit 1
}

& winget source reset --force
& winget source update

# ── Install apps ──────────────────────────────────────────────────────────────
Write-Output "Installing apps..."
foreach ($AppID in $Config.AppsToInstall) {
    Write-Output "  Installing: $AppID"
    & winget install --id $AppID --silent --accept-package-agreements --accept-source-agreements --scope machine
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "  Failed to install $AppID (exit code $LASTEXITCODE) — continuing..."
    }
}

# ── Remove bloatware ─────────────────────────────────────────────────────────
Write-Output "Removing bloatware..."
foreach ($Package in $Config.BloatwareToRemove) {
    Write-Output "  Removing: $Package"
    Get-AppxPackage -Name $Package -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
}

# ── Done ─────────────────────────────────────────────────────────────────────
Write-Output "Provisioning complete. Rebooting in 10 seconds..."
Start-Sleep -Seconds 10
Restart-Computer -Force
