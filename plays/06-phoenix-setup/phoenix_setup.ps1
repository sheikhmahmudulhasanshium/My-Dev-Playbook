<#
.SYNOPSIS
  An interactive, role-based, and hardware-aware setup script for a new developer machine.
  It allows users to install profiles (Frontend, Backend) or individual tools like Git, VS Code,
  Node.js, Docker, and Visual Studio.

.DESCRIPTION
  Play #6 from My-Dev-Playbook. The Phoenix Setup script provides a flexible way to provision a
  new Windows machine. It checks system RAM, is idempotent (re-runnable), uses the winget package
  manager for safety, and requires administrator privileges. A log file is created in Documents on any error.

.NOTES
  Author: Sheikh Mahmudul Hasan Shium
  License: MIT
#>

# --- SCRIPT START ---

# =============================================================================
#  LOGGING & STATE
# =============================================================================
$logFile = Join-Path $HOME "Documents\phoenix-setup-log.txt"
$global:state = @{
    git = $false; vscode = $false; node = $false; docker = $false;
    postman = $false; vs_community = $false; pnpm = $false; yarn = $false; nest = $false
}

Function Add-LogEntry {
    param([string]$Message, [string]$Category = 'INFO')
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$($Category.ToUpper())] $Message"
    try { Add-Content -Path $logFile -Value $logMessage -ErrorAction Stop } catch {}
}

# =============================================================================
#  HELPER FUNCTIONS
# =============================================================================
Function Test-IsAdmin { return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
Function Test-CommandExists { param([string]$Command) return -not ([string]::IsNullOrEmpty((Get-Command $Command -ErrorAction SilentlyContinue))) }
Function Get-SystemRamGB { try { return [Math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB) } catch { Add-LogEntry "Could not get system RAM." "WARNING"; return 0 } }

Function Update-InstallationStatus {
    $global:state.git = Test-CommandExists "git"
    $global:state.vscode = Test-CommandExists "code"
    $global:state.node = Test-CommandExists "node"
    $global:state.docker = Test-CommandExists "docker"
    $global:state.vs_community = Test-CommandExists "devenv"
    $global:state.postman = (Get-Package -Name 'Postman' -ErrorAction SilentlyContinue) -ne $null
    if ($global:state.node) { $global:state.pnpm = Test-CommandExists "pnpm"; $global:state.yarn = Test-CommandExists "yarn"; $global:state.nest = Test-CommandExists "nest" }
}

Function Check-Ram {
    param([int]$SystemRam, [int]$RecommendedRam, [string]$AppName)
    $continue = $true
    if ($SystemRam -lt ($RecommendedRam / 2)) {
        Write-Host "`n⚠️ STRONG WARNING: Your system has less than $($RecommendedRam / 2) GB of RAM." -ForegroundColor Red
        Write-Host "$AppName is very unlikely to run well. It is strongly recommended to skip this installation."
        $confirm = Read-Host "Are you absolutely sure you want to continue? (y/N)"
        if ($confirm.ToLower() -ne 'y') { $continue = $false }
    } elseif ($SystemRam -lt $RecommendedRam) {
        Write-Host "`n⚠️ WARNING: Your system has less than $RecommendedRam GB of RAM." -ForegroundColor Yellow
        Write-Host "$AppName will run, but performance may be limited, especially when multitasking."
        $confirm = Read-Host "Do you want to continue with the installation? (Y/n)"
        if ($confirm.ToLower() -eq 'n') { $continue = $false }
    }
    return $continue
}

Function Install-WithWinget {
    param([string]$AppName, [string]$AppId)
    Write-Host "`n🔧 Installing $AppName via winget..." -ForegroundColor Yellow; Add-LogEntry "Attempting to install $AppName ($AppId)."
    try {
        $process = Start-Process winget -ArgumentList "install --id $AppId -e --accept-source-agreements --accept-package-agreements" -Wait -PassThru
        if ($process.ExitCode -ne 0) { throw "Winget process exited with code: $($process.ExitCode)" }
        Write-Host "✅ Successfully installed $AppName." -ForegroundColor Green; Add-LogEntry "Successfully installed $AppName."
        return $true
    } catch {
        $errorMessage = "❌ FAILED to install $AppName. Error: $($_.Exception.Message)"
        Write-Host $errorMessage -ForegroundColor Red; Add-LogEntry $errorMessage "ERROR"
        return $false
    }
}

Function Install-NpmGlobal {
    param([string]$PackageName)
    Write-Host "   - 🔧 Installing $PackageName globally..." -ForegroundColor Yellow; Add-LogEntry "Installing $PackageName globally."
    try { npm install -g $PackageName; Write-Host "   - ✅ $PackageName installed." -ForegroundColor Green }
    catch { $errorMessage = "   - ❌ FAILED to install $PackageName. Error: $($_.Exception.Message)"; Write-Host $errorMessage -ForegroundColor Red; Add-LogEntry $errorMessage "ERROR" }
}

Function Install-NodeEcosystem {
    if (-not $global:state.node) {
        if(Install-WithWinget "Node.js (LTS)" "OpenJS.NodeJS.LTS") { Install-NpmGlobal "pnpm"; Install-NpmGlobal "yarn"; Install-NpmGlobal "@nestjs/cli" }
    } else {
        Write-Host "`nNode.js is already installed. Checking global packages..." -ForegroundColor Cyan; Install-NpmGlobal "pnpm"; Install-NpmGlobal "yarn"; Install-NpmGlobal "@nestjs/cli"
    }
}

Function Show-Menu {
    param([int]$SystemRam)
    Clear-Host; Update-InstallationStatus
    Function Status { param($key) if ($global:state[$key]) { "[INSTALLED]" } else { "[NOT INSTALLED]" } }
    Function RamWarning { param($recRam, $appName) if (($SystemRam -lt $recRam) -and ($SystemRam -gt 0)) { Write-Host "(Warning: Low RAM)" -NoNewline -ForegroundColor Yellow; "" } else { "" } }

    Write-Host "--- 🔥 Phoenix Setup Menu ---" -ForegroundColor Cyan
    if ($SystemRam -gt 0) { Write-Host "Detected System RAM: $SystemRam GB`n" }
    Write-Host "Choose a profile or install tools individually:`n"
    Write-Host "--- Profiles ---"
    Write-Host "[1] Install Frontend Profile (Git, VS Code, Node.js)"
    Write-Host "[2] Install Backend Profile (Git, Node.js, Docker, Postman)"
    Write-Host "[3] Install Full-Stack Profile (All of the above)"
    Write-Host "`n--- Core Tools ---"
    Write-Host "[4] Install Git ................. $(Status 'git')"
    Write-Host "[5] Install VS Code ............. $(Status 'vscode')"
    Write-Host "[6] Install Node.js Ecosystem ... $(Status 'node')"
    Write-Host "`n--- Heavy IDEs & Containers (Optional) ---"
    Write-Host "[7] Install Docker Desktop ...... $(Status 'docker') $(RamWarning 16 'Docker')"
    Write-Host "[8] Install Visual Studio 2022 .. $(Status 'vs_community') $(RamWarning 16 'Visual Studio')"
    Write-Host "`n--- API Tools (Optional) ---"
    Write-Host "[9] Install Postman ............. $(Status 'postman')"
    Write-Host "`n--- Configuration ---"
    Write-Host "[C] Configure Git & Show Next Steps"
    Write-Host "[Q] Quit`n"
}

Function Show-PostInstallGuidance {
    Clear-Host; Write-Host "--- 🚀 Next Steps: Final Configuration ---" -ForegroundColor Cyan
    Write-Host "`n1. CONFIGURE GIT:" -ForegroundColor Yellow
    if ($global:state.git) { $gitName = Read-Host "   - Enter your full name"; $gitEmail = Read-Host "   - Enter your email"; git config --global user.name "$gitName"; git config --global user.email "$gitEmail"; Add-LogEntry "Configured git user."; Write-Host "   ✅ Git user configured." -ForegroundColor Green } 
    else { Write-Host "   - Git not installed." -ForegroundColor Gray }
    Write-Host "`n2. CONNECT VS CODE & SYNC SETTINGS:" -ForegroundColor Yellow
    if ($global:state.vscode) { Write-Host "   - Open VS Code, click the 'Accounts' icon (bottom-left) and 'Sign in with GitHub'."; Add-LogEntry "Provided VS Code sync instructions." } 
    else { Write-Host "   - VS Code not installed." -ForegroundColor Gray }
    Write-Host "`n3. START YOUR LOCAL DATABASE (Requires Docker):" -ForegroundColor Yellow
    if ($global:state.docker) { Write-Host "   - After Docker starts, run this in a terminal: `n   docker run --name pg-local -e POSTGRES_PASSWORD=mysecretpassword -p 5432:5432 -d postgres" -ForegroundColor White; Add-LogEntry "Provided Docker instructions." } 
    else { Write-Host "   - Docker not installed." -ForegroundColor Gray }
    Read-Host "`nPress Enter to return to the main menu..."
}

# =============================================================================
#  MAIN SCRIPT LOGIC
# =============================================================================
if (-not (Test-IsAdmin)) { Write-Host "`n❌ ERROR: Administrator privileges required." -ForegroundColor Red; Read-Host "Press Enter to exit..."; exit 1 }

New-Item -Path $logFile -ItemType File -Force | Out-Null
Add-LogEntry "Phoenix Setup script started." -Category 'START'
$systemRam = Get-SystemRamGB
Add-LogEntry "Detected $systemRam GB of system RAM."

$choice = ''
do {
    Show-Menu -SystemRam $systemRam
    $choice = Read-Host "Enter your choice"
    $pause = $true

    switch ($choice) {
        '1' { # Frontend Profile
            if (-not $global:state.git) { Install-WithWinget "Git" "Git.Git" }
            if (-not $global:state.vscode) { Install-WithWinget "VS Code" "Microsoft.VisualStudioCode" }
            Install-NodeEcosystem
        }
        '2' { # Backend Profile
            if (-not $global:state.git) { Install-WithWinget "Git" "Git.Git" }
            Install-NodeEcosystem
            if (-not $global:state.docker) { if (Check-Ram -SystemRam $systemRam -RecommendedRam 16 -AppName "Docker") { Install-WithWinget "Docker Desktop" "Docker.DockerDesktop" } }
            if (-not $global:state.postman) { Install-WithWinget "Postman" "Postman.Postman" }
        }
        '3' { # Full-Stack Profile
            if (-not $global:state.git) { Install-WithWinget "Git" "Git.Git" }
            if (-not $global:state.vscode) { Install-WithWinget "VS Code" "Microsoft.VisualStudioCode" }
            Install-NodeEcosystem
            if (-not $global:state.docker) { if (Check-Ram -SystemRam $systemRam -RecommendedRam 16 -AppName "Docker") { Install-WithWinget "Docker Desktop" "Docker.DockerDesktop" } }
            if (-not $global:state.postman) { Install-WithWinget "Postman" "Postman.Postman" }
        }
        '4' { if (-not $global:state.git) { Install-WithWinget "Git" "Git.Git" } else {$pause = $false} }
        '5' { if (-not $global:state.vscode){ Install-WithWinget "VS Code" "Microsoft.VisualStudioCode" } else {$pause = $false} }
        '6' { Install-NodeEcosystem }
        '7' { if (-not $global:state.docker) { if (Check-Ram -SystemRam $systemRam -RecommendedRam 16 -AppName "Docker") { Install-WithWinget "Docker Desktop" "Docker.DockerDesktop" } } else {$pause = $false} }
        '8' { if (-not $global:state.vs_community) { if (Check-Ram -SystemRam $systemRam -RecommendedRam 16 -AppName "Visual Studio") { Install-WithWinget "Visual Studio 2022 Community" "Microsoft.VisualStudio.2022.Community" } } else {$pause = $false} }
        '9' { if (-not $global:state.postman){ Install-WithWinget "Postman" "Postman.Postman" } else {$pause = $false} }
        'c' { Show-PostInstallGuidance; $pause = $false }
    }
    if($pause -and $choice -ne 'q') { Read-Host "`nFinished. Press Enter to return to menu." }
} while ($choice -ne 'q')

Write-Host "`nPhoenix Setup finished. Exiting."
Add-LogEntry "User exited the script." -Category 'STOP'