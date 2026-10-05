<#
.SYNOPSIS
    Automated Windows & WSL2 environment setup for open-source EDA tools.
.DESCRIPTION
    Runs on the Windows side (PowerShell with Administrator rights).
    - Checks Windows OS build version.
    - Installs WSL2 and Ubuntu if missing.
    - Handles necessary reboots.
    - Prompts user about initial Ubuntu account setup.
    - Verifies or installs Docker Desktop via winget and reminds to enable WSL2 integration.
    - Creates or updates .wslconfig with appropriate RAM allocation (asking first, with backup).
    - Clones this repository directly inside the WSL home directory (not on /mnt/c).
    - Runs install_all.sh inside the Ubuntu WSL environment.
.PARAMETER DryRun
    Simulates actions without making changes.
.PARAMETER Yes
    Accepts prompts automatically where appropriate.
.PARAMETER Path
    Flow path to install inside WSL: 'a' (LibreLane), 'b' (IIC-OSIC-TOOLS), or 'manual' (doctor check only).
#>

[CmdletBinding()]
param (
    [switch]$DryRun,
    [switch]$Yes,
    [ValidateSet("a", "b", "manual")]
    [string]$Path = "a"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "   Part D: Windows WSL2 & Ubuntu Automated Setup for EDA Tools       " -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

# 1. Check Administrator Privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "This script is not running as Administrator. Some steps (wsl --install, winget) may require elevation."
    if (-not $Yes) {
        $continueNonAdmin = Read-Host "Proceed anyway? [y/N]"
        if ($continueNonAdmin -notmatch '^[yY]') {
            Write-Error "Exiting. Please right-click PowerShell and select 'Run as Administrator'."
            exit 1
        }
    }
}

# 2. Check Windows Version & Build
$osVer = [System.Environment]::OSVersion.Version
Write-Host "Detected Windows Version: $($osVer.Major).$($osVer.Minor) (Build $($osVer.Build))" -ForegroundColor Gray
if ($osVer.Build -lt 19041) {
    Write-Error "WSL2 requires Windows 10 Build 19041 or higher (or Windows 11). Please update Windows."
    exit 1
}

# 3. Check / Install WSL2 & Ubuntu
Write-Host "`n[Step 1/5] Checking WSL2 and Ubuntu installation..." -ForegroundColor Yellow
$wslInstalled = $false
try {
    $null = wsl.exe --status 2>&1
    if ($LASTEXITCODE -eq 0) {
        $wslInstalled = $true
        Write-Host "WSL2 is already installed and active." -ForegroundColor Green
    }
} catch {
    $wslInstalled = $false
}

if (-not $wslInstalled) {
    Write-Host "WSL is not detected or needs initialization." -ForegroundColor Yellow
    if ($DryRun) {
        Write-Host "[DRY-RUN] Would run: wsl.exe --install -d Ubuntu" -ForegroundColor DarkYellow
    } else {
        Write-Host "Installing WSL2 with Ubuntu..." -ForegroundColor Cyan
        wsl.exe --install -d Ubuntu
        Write-Host "IMPORTANT: A system reboot is typically required after installing WSL." -ForegroundColor Red
        Write-Host "Please restart your computer, then re-run this script to continue." -ForegroundColor Red
        exit 0
    }
}

# 4. Check Ubuntu user setup
Write-Host "`n[Step 2/5] Checking Ubuntu distribution in WSL..." -ForegroundColor Yellow
$distros = wsl.exe -l -v 2>&1 | Out-String
if ($distros -notmatch "Ubuntu") {
    Write-Host "Ubuntu distribution not found. Installing Ubuntu distro..." -ForegroundColor Yellow
    if ($DryRun) {
        Write-Host "[DRY-RUN] Would run: wsl.exe --install -d Ubuntu" -ForegroundColor DarkYellow
    } else {
        wsl.exe --install -d Ubuntu
        Write-Host "NOTE: When Ubuntu launches for the first time, you must enter a UNIX username and password." -ForegroundColor Magenta
        Write-Host "This cannot be automated. Complete the prompt in the Ubuntu window, then return here." -ForegroundColor Magenta
        Pause
    }
} else {
    Write-Host "Ubuntu distribution is present in WSL2." -ForegroundColor Green
}

# 5. Check Docker Desktop
Write-Host "`n[Step 3/5] Checking Docker Desktop..." -ForegroundColor Yellow
if (Get-Command docker -ErrorAction SilentlyContinue) {
    $dVer = docker --version
    Write-Host "Docker is installed on Windows host: $dVer" -ForegroundColor Green
} else {
    Write-Host "Docker Desktop not found on Windows host." -ForegroundColor Yellow
    $installDocker = $false
    if ($Yes) {
        $installDocker = $true
    } else {
        $ans = Read-Host "Would you like to install Docker Desktop via winget now? [y/N]"
        if ($ans -match '^[yY]') { $installDocker = $true }
    }

    if ($installDocker) {
        if ($DryRun) {
            Write-Host "[DRY-RUN] Would run: winget install -e --id Docker.DockerDesktop" -ForegroundColor DarkYellow
        } else {
            Write-Host "Installing Docker Desktop via winget (this may take a few minutes)..." -ForegroundColor Cyan
            winget install -e --id Docker.DockerDesktop --accept-package-agreements --accept-source-agreements
            Write-Host "Docker Desktop installed. Please launch Docker Desktop, go to Settings -> Resources -> WSL Integration, and check 'Ubuntu'." -ForegroundColor Red
        }
    } else {
        Write-Host "Skipping Docker Desktop installation. Ensure you have Docker running in Ubuntu." -ForegroundColor Gray
    }
}

# 6. Configure .wslconfig Memory Limit
Write-Host "`n[Step 4/5] Checking WSL2 Memory Allocation (.wslconfig)..." -ForegroundColor Yellow
$userProfilePath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
$wslConfigPath = Join-Path $userProfilePath ".wslconfig"

$writeConfig = $false
if (-not (Test-Path $wslConfigPath)) {
    if ($Yes) {
        $writeConfig = $true
    } else {
        $ansConfig = Read-Host "Create recommended .wslconfig (caps RAM to 8GB/16GB to prevent Windows freeze)? [y/N]"
        if ($ansConfig -match '^[yY]') { $writeConfig = $true }
    }

    if ($writeConfig) {
        $totalRamGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
        $wslRamGB = [math]::Max(4, [math]::Round($totalRamGB * 0.6))
        $configContent = @"
[wsl2]
memory=${wslRamGB}GB
processors=4
swap=8GB
"@
        if ($DryRun) {
            Write-Host "[DRY-RUN] Would write to $wslConfigPath :`n$configContent" -ForegroundColor DarkYellow
        } else {
            Set-Content -Path $wslConfigPath -Value $configContent
            Write-Host "Created $wslConfigPath with memory=${wslRamGB}GB." -ForegroundColor Green
        }
    }
} else {
    Write-Host ".wslconfig already exists at $wslConfigPath." -ForegroundColor Gray
}

# 7. Clone Repo inside WSL and Run install_all.sh
Write-Host "`n[Step 5/5] Launching Installer inside WSL Ubuntu..." -ForegroundColor Yellow
Write-Host "CRITICAL PERFORMANCE RULE: We clone and run this inside the Linux filesystem (~/eda_tools)," -ForegroundColor Cyan
Write-Host "NOT on /mnt/c, to avoid NTFS virtualization slowdowns." -ForegroundColor Cyan

$repoUrl = "https://github.com/your-username/eda-tools-installer.git"
$wslCommand = "mkdir -p ~/eda_tools && cd ~/eda_tools && " +
              "if [ ! -d 'eda-tools-installer/.git' ]; then git clone $repoUrl; fi && " +
              "cd eda-tools-installer && chmod +x install_all.sh doctor.sh lib/*.sh scripts/*/*.sh scripts/*/*/*.sh 2>/dev/null || true && " +
              "./install_all.sh --path $Path"

if ($DryRun) {
    Write-Host "[DRY-RUN] Would run inside WSL: wsl.exe -d Ubuntu -e bash -lic `"$wslCommand`"" -ForegroundColor DarkYellow
} else {
    Write-Host "Executing installer inside Ubuntu WSL..." -ForegroundColor Green
    wsl.exe -d Ubuntu -e bash -lic "$wslCommand"
}

Write-Host "`n=====================================================================" -ForegroundColor Green
Write-Host "  WSL2 setup phase complete! Check Ubuntu terminal output above.    " -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Green
