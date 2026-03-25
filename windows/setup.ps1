[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

function Test-IsAdministrator {
    $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [System.Security.Principal.WindowsPrincipal]::new($currentIdentity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    Write-Host "Requesting administrative privileges..."
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}


# --- 1. Apply Registry State via DSC v3 ---
$dscConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "registry.dsc.yaml"

if (-not (Get-Command -Name dsc -ErrorAction SilentlyContinue)) {
    Write-Host "Installing DSC v3 with winget..."
    winget install --id Microsoft.DSC --exact --accept-package-agreements --accept-source-agreements --disable-interactivity

    $env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    if (-not (Get-Command -Name dsc -ErrorAction SilentlyContinue)) {
        throw "DSC v3 was installed, but dsc.exe was not resolvable in the current session."
    }
}

if (-not (Test-Path -LiteralPath $dscConfigFile)) {
    throw "Missing DSC config file: $dscConfigFile"
}

Write-Host "Applying registry state with DSC v3..."
dsc config set --file $dscConfigFile


# --- 2. Deploy WSL Configuration ---
$wslConfFile = Join-Path -Path $PSScriptRoot -ChildPath "wsl.conf"
if (Test-Path -LiteralPath $wslConfFile) {
    $wslDistros = $null

    if (Get-Command -Name wsl.exe -ErrorAction SilentlyContinue) {
        $wslDistros = wsl.exe -l -q 2>$null
    }

    if ($wslDistros) {
        Write-Host "Deploying wsl.conf to default WSL distribution..."
        Get-Content -Path $wslConfFile | wsl.exe -u root tee /etc/wsl.conf | Out-Null

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to deploy wsl.conf to WSL."
        } else {
            Write-Host "Deployed wsl.conf successfully."
        }
    }
}


# --- 3. Tweak Microsoft Store Search Suggestions ---
$storeDbPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState\store.db"
if (Test-Path -LiteralPath $storeDbPath) {
    Write-Host "Blocking Microsoft Store search suggestions..."
    icacls.exe $storeDbPath /deny "Everyone:F"
} else {
    Write-Warning "Skipping Microsoft Store search suggestion tweak because the Store database was not found: $storeDbPath"
}


# --- 4. Import Winget Packages ---
$hostname = $env:COMPUTERNAME
$wingetJsonFile = Join-Path -Path $PSScriptRoot -ChildPath "$hostname.json"

if (-not (Test-Path -LiteralPath $wingetJsonFile)) {
    Write-Warning "No exact machine profile found for hostname: $hostname"

    $availableConfigs = Get-ChildItem -Path $PSScriptRoot -Filter "*.json" | Where-Object {
        $_.Name -ne "winget.json" -and $_.Name -ne "terminal.json"
    }

    if ($availableConfigs.Count -gt 0) {
        Write-Host ""
        Write-Host "Please select a configuration profile to apply:"

        for ($i = 0; $i -lt $availableConfigs.Count; $i++) {
            Write-Host "[$($i + 1)] $($availableConfigs[$i].BaseName)"
        }
        Write-Host "[S] Skip"

        $validChoices = 1..$availableConfigs.Count | ForEach-Object { $_.ToString() }
        $validChoices += "S"

        $result = ""
        while ($result -notin $validChoices) {
            $prompt = Read-Host "Select a profile"
            if ($prompt) {
                $result = $prompt.Trim().ToUpper()
            }
        }

        if ($result -eq "S") {
            Write-Host "Skipping winget profile import."
            $wingetJsonFile = $null
        } else {
            $selectedIndex = [int]$result - 1
            $wingetJsonFile = $availableConfigs[$selectedIndex].FullName
            Write-Host "Selected profile: $($availableConfigs[$selectedIndex].BaseName)"
        }
    } else {
        Write-Host "No fallback configuration profiles found in $PSScriptRoot."
        $wingetJsonFile = $null
    }
} else {
    Write-Host "Auto-detected winget profile for hostname: $hostname"
}

if ($null -ne $wingetJsonFile -and (Test-Path -LiteralPath $wingetJsonFile)) {
    Write-Host "Importing packages..."
    winget import --import-file $wingetJsonFile --accept-package-agreements --accept-source-agreements --disable-interactivity

    # Refresh PATH in current session to pick up newly installed tools like oh-my-posh
    $env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    # --- 5. Install Oh My Posh Fonts ---
    Write-Host "Installing Oh My Posh fonts..."
    $fonts = @("Meslo", "JetBrainsMono")
    foreach ($font in $fonts) {
        Write-Host "Installing $font Nerd Font..."
        oh-my-posh font install $font
    }
}


# --- 6. Deploy Dotfiles via Chezmoi ---
Write-Host "Deploying dotfiles with chezmoi..."
if (-not (Get-Command -Name chezmoi -ErrorAction SilentlyContinue)) {
    Write-Host "Installing chezmoi..."
    winget install --id twpayne.chezmoi --exact --accept-package-agreements --accept-source-agreements --disable-interactivity

    $env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

$chezmoiSourceDir = Join-Path -Path $PSScriptRoot -ChildPath "chezmoi"
if ((Get-Command -Name chezmoi -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $chezmoiSourceDir)) {
    chezmoi apply --source $chezmoiSourceDir --force
    Write-Host "Deployed dotfiles successfully."
} elseif (-not (Get-Command -Name chezmoi -ErrorAction SilentlyContinue)) {
    Write-Warning "Failed to install chezmoi. Skipping dotfiles deployment."
} else {
    Write-Warning "Chezmoi source directory not found: $chezmoiSourceDir"
}


# --- 7. Run PowerShell Setup Script ---
$powershellSetupScript = Join-Path -Path $PSScriptRoot -ChildPath "PowerShell_setup.ps1"
if (Test-Path -LiteralPath $powershellSetupScript) {
    Write-Host "Running PowerShell setup script..."
    & $powershellSetupScript
}

Write-Host "Windows setup changes applied. Restart Explorer or sign out to pick up the folder view change."
