# Universal gaming setup for Windows 10 and 11
# Inspired by safe, reversible concepts used by prolix-oc/Refyne (MIT).
# This script does not copy Refyne's source; it provides a smaller, cross-PC setup.

$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Confirm-Action {
    param([Parameter(Mandatory)][string]$Message)

    if (-not $confirmChanges) {
        return $true
    }

    $answer = Read-Host "$Message [Y/N]"
    return $answer.Trim() -match "^[Yy]"
}

function Ensure-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "winget is unavailable. Install 'App Installer' from Microsoft Store." -ForegroundColor Red
        return $false
    }
    return $true
}

function Test-PackageInstalled {
    param(
        [Parameter(Mandatory)][string]$Id
    )

    $listing = @(& winget list --id $Id --exact --accept-source-agreements 2>&1)
    $exitCode = $LASTEXITCODE
    $listingText = $listing -join "`n"
    $escapedId = [regex]::Escape($Id)

    if ($listingText -match "(?i)(?<![\w.+-])$escapedId(?![\w.+-])") {
        return $true
    }

    if ($exitCode -eq 0 -or $listingText -match "(?i)no installed package found") {
        return $false
    }

    Write-Host "Could not check whether package '$Id' is installed. winget returned exit code $exitCode." -ForegroundColor Red
    if ($listingText) {
        Write-Host $listingText -ForegroundColor DarkRed
    }
    return $null
}

function Install-Package {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Id
    )

    if (-not (Ensure-Winget)) {
        return
    }

    $isInstalled = Test-PackageInstalled -Id $Id
    if ($null -eq $isInstalled) {
        return
    }
    if ($isInstalled) {
        Write-Host "$Name is already installed." -ForegroundColor Green
        return
    }

    if (Confirm-Action "Install $Name?") {
        winget install --id $Id --exact --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$Name installed." -ForegroundColor Green
        }
        else {
            Write-Host "$Name could not be installed." -ForegroundColor Red
        }
    }
    else {
        Write-Host "Skipping $Name." -ForegroundColor Yellow
    }
}

function Set-RegistryValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][object]$Value,
        [Parameter(Mandatory)][ValidateSet("String", "DWord", "QWord")][string]$Type
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

function Backup-RegistryKey {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$BackupPath
    )

    if (-not (Get-Command reg.exe -ErrorAction SilentlyContinue)) {
        return
    }

    $providerPath = $Path
    $providerPath = $providerPath.Replace("HKCU:\", "HKEY_CURRENT_USER\")
    $providerPath = $providerPath.Replace("HKLM:\", "HKEY_LOCAL_MACHINE\")
    & reg.exe export $providerPath $BackupPath /y | Out-Null
}

function Get-GpuDetails {
    $gpus = Get-CimInstance Win32_VideoController |
        Where-Object { $_.Name -or $_.AdapterCompatibility }

    return $gpus | Select-Object Name, AdapterCompatibility, DriverVersion, DriverDate
}

function Write-OptimizationPlan {
    param(
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)][array]$GpuDetails
    )

    $gpuText = if ($GpuDetails.Count -gt 0) {
        ($GpuDetails | ForEach-Object {
            "- $($_.Name) [$($_.AdapterCompatibility)], driver $($_.DriverVersion)"
        }) -join "`r`n"
    }
    else {
        "- No GPU detected"
    }

    $content = @"
Gaming PC Optimization Plan
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Detected GPU:
$gpuText

Recommended next steps:
1. Install the latest GPU driver from the GPU vendor's official application or website.
2. Open the GPU control panel and set the game to use the high-performance GPU.
3. Disable unnecessary overlays in Steam, Epic Games, Discord, or recording software.
4. Benchmark before and after each change. Revert changes that reduce stability or frame time.
5. Keep BIOS, chipset, GPU, monitor, and controller firmware updated only from official vendors.

Applied changes are logged in $LogPath.
"@

    Set-Content -LiteralPath $OutputPath -Value $content -Encoding utf8
}

if (-not (Test-IsAdministrator)) {
    Write-Host "Please run this script from an elevated PowerShell window." -ForegroundColor Red
    exit 1
}

$confirmChanges = $true
$mode = Read-Host "Choose setup mode [A] Automatic [M] Manual"
if ($mode -notmatch "^[AaMm]$") {
    Write-Host "Choose A for Automatic or M for Manual." -ForegroundColor Red
    exit 1
}

$applySetup = $true
if ($mode -match "^[Aa]$") {
    $applySetup = Confirm-Action "Apply automatic app installs and gaming settings?"
    if ($applySetup) {
        $confirmChanges = $false
    }
}

$desktop = [Environment]::GetFolderPath("Desktop")
$backupDirectory = Join-Path $env:LOCALAPPDATA "GamingSetupBackup"
$planPath = Join-Path $desktop "Gaming-Optimization-Plan.txt"
$LogPath = Join-Path $backupDirectory "gaming-setup.log"

New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null
"Gaming setup started $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" |
    Set-Content -LiteralPath $LogPath -Encoding utf8

$os = Get-CimInstance Win32_OperatingSystem
Write-Host "Detected: $($os.Caption) $($os.OSArchitecture)" -ForegroundColor Cyan

$gpuDetails = @(Get-GpuDetails)
Write-Host "`nDetected graphics hardware:" -ForegroundColor Cyan
if ($gpuDetails.Count -eq 0) {
    Write-Host "No GPU details detected."
}
else {
    $gpuDetails | Format-Table Name, AdapterCompatibility, DriverVersion, DriverDate -AutoSize
}

if ($applySetup -and ($mode -match "^[Aa]$" -or (Confirm-Action "Create a Windows system restore point before changes?"))) {
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction Stop
        Checkpoint-Computer -Description "Gaming setup before optimization" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "System restore point created." -ForegroundColor Green
        "Created system restore point" | Add-Content -LiteralPath $LogPath
    }
    catch {
        Write-Host "Restore point could not be created: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

if ($applySetup) {
    $configureApps = $mode -match "^[Aa]$"
    if (-not $configureApps) {
        $packageMode = Read-Host "Configure apps now? [A]Yes [N]No"
        $configureApps = $packageMode -match "^[Aa]"
    }

    if ($configureApps) {
        Install-Package "Steam" "Valve.Steam"
        Install-Package "Epic Games Launcher" "EpicGames.EpicGamesLauncher"
        Install-Package "Spotify" "Spotify.Spotify"
        Install-Package "Xbox" "Microsoft.GamingApp"
        Install-Package "Visual C++ 2015-2022 x64" "Microsoft.VCRedist.2015+.x64"
        Install-Package "Visual C++ 2015-2022 x86" "Microsoft.VCRedist.2015+.x86"
        Install-Package "DirectX End-User Runtime" "Microsoft.DirectX"
    }
}

if ($applySetup -and (Confirm-Action "Enable Windows Game Mode?")) {
    $gameBarPath = "HKCU:\Software\Microsoft\GameBar"
    Backup-RegistryKey -Path $gameBarPath -BackupPath (Join-Path $backupDirectory "GameBar.reg")
    Set-RegistryValue -Path $gameBarPath -Name "AllowAutoGameMode" -Value 1 -Type DWord
    Set-RegistryValue -Path $gameBarPath -Name "AutoGameModeEnabled" -Value 1 -Type DWord
    Write-Host "Windows Game Mode enabled." -ForegroundColor Green
    "Enabled Windows Game Mode" | Add-Content -LiteralPath $LogPath
}

if ($applySetup -and (Confirm-Action "Set the active power plan to High Performance?")) {
    $scheme = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    & powercfg.exe /setactive $scheme
    if ($LASTEXITCODE -eq 0) {
        Write-Host "High Performance power plan activated." -ForegroundColor Green
        "Activated High Performance power plan" | Add-Content -LiteralPath $LogPath
    }
    else {
        Write-Host "The High Performance power plan was not available." -ForegroundColor Yellow
    }
}

if ($applySetup -and (Confirm-Action "Enable Hardware-accelerated GPU scheduling?")) {
    $gpuPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    Backup-RegistryKey -Path $gpuPath -BackupPath (Join-Path $backupDirectory "GraphicsDrivers.reg")
    Set-RegistryValue -Path $gpuPath -Name "HwSchMode" -Value 2 -Type DWord
    Write-Host "HAGS was enabled. A restart is required." -ForegroundColor Yellow
    "Enabled HAGS; restart required" | Add-Content -LiteralPath $LogPath
}

Write-OptimizationPlan -OutputPath $planPath -GpuDetails $gpuDetails
"Plan created: $planPath" | Add-Content -LiteralPath $LogPath

Write-Host "`nGaming setup complete." -ForegroundColor Green
Write-Host "Plan: $planPath"
Write-Host "Backups and log: $backupDirectory"
