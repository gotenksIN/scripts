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

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8


# --- 1. Apply System Configuration via WinGet Configure (DSC v3) ---
$configFile = Join-Path -Path $PSScriptRoot -ChildPath "configuration.dsc.yaml"
if (-not (Test-Path -LiteralPath $configFile)) {
    throw "Missing configuration file: $configFile"
}

Write-Host "Ensuring winget configure is enabled..."
& winget configure --enable --disable-interactivity 2>$null

$ownershipScript = Join-Path -Path $PSScriptRoot -ChildPath "scripts\Take-FolderTypesOwnership.ps1"
if (Test-Path -LiteralPath $ownershipScript) {
    Write-Host "Taking ownership and adjusting permissions for protected Explorer registry keys..."
    & $ownershipScript
}

Write-Host "Applying system state with winget configure..."
winget configure --file $configFile --accept-configuration-agreements --disable-interactivity


# --- 2. Block Microsoft Store Search Suggestions ---
$storeDbDir = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState"
$storeDbPath = Join-Path -Path $storeDbDir -ChildPath "store.db"

Write-Host "Blocking Microsoft Store search suggestions..."
if (-not (Test-Path -LiteralPath $storeDbDir)) {
    New-Item -ItemType Directory -Path $storeDbDir -Force | Out-Null
}

if (Test-Path -LiteralPath $storeDbPath) {
    Set-ItemProperty -Path $storeDbPath -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
    Remove-Item -Path $storeDbPath -Force -ErrorAction SilentlyContinue
}

New-Item -ItemType File -Path $storeDbPath -Value "" -Force | Out-Null
Set-ItemProperty -Path $storeDbPath -Name IsReadOnly -Value $true -Force
Write-Host "Successfully blocked Microsoft Store search suggestions."


# --- 3. Import WinGet Packages ---
$hostname = $env:COMPUTERNAME
$wingetJsonFile = Join-Path -Path $PSScriptRoot -ChildPath "$hostname.json"

if (-not (Test-Path -LiteralPath $wingetJsonFile)) {
    Write-Warning "No exact machine profile found for hostname: $hostname"

    $availableConfigs = Get-ChildItem -Path $PSScriptRoot -Filter "*.json"
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

    $env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    if (Get-Command -Name oh-my-posh -ErrorAction SilentlyContinue) {
        Write-Host "Installing Oh My Posh fonts..."
        $fonts = @("Meslo", "JetBrainsMono")
        foreach ($font in $fonts) {
            Write-Host "Installing $font Nerd Font..."
            oh-my-posh font install $font
        }
    }
}


# --- 4. Deploy Dotfiles ---
$dotfilesScript = Join-Path -Path $PSScriptRoot -ChildPath "scripts\Deploy-Dotfiles.ps1"
if (Test-Path -LiteralPath $dotfilesScript) {
    Write-Host "Deploying dotfiles..."
    & $dotfilesScript
    Write-Host "Deployed dotfiles successfully."
} else {
    Write-Warning "Deploy-Dotfiles script not found: $dotfilesScript"
}


# --- 5. Install Essential PowerShell Modules ---
Write-Host "Installing PowerShell modules..."
$modules = @("Microsoft.WinGet.CommandNotFound", "PSWindowsUpdate", "Terminal-Icons")
foreach ($module in $modules) {
    Install-PSResource -Name $module -TrustRepository -Scope AllUsers -ErrorAction SilentlyContinue
}

Write-Host "Windows setup completed successfully. Restart Explorer or sign out to pick up changes."
