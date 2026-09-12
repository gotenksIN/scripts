[CmdletBinding()]
param(
    [string]$DotfilesRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) "dotfiles")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$DotfilesRoot = (Resolve-Path -LiteralPath $DotfilesRoot).ProviderPath

function Set-FileSymbolicLink {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Target
    )

    if (-not (Test-Path -LiteralPath $Target -PathType Leaf)) {
        throw "Missing dotfile: $Target"
    }

    $parentDirectory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parentDirectory)) {
        New-Item -ItemType Directory -Path $parentDirectory -Force | Out-Null
    }

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Force
    }

    New-Item -ItemType SymbolicLink -Path $Path -Target $Target -Force | Out-Null
}

$profilePath = $PROFILE
Set-FileSymbolicLink -Path $profilePath -Target (Join-Path $DotfilesRoot "Microsoft.PowerShell_profile.ps1")

$topgradePath = Join-Path $env:APPDATA "topgrade.toml"
Set-FileSymbolicLink -Path $topgradePath -Target (Join-Path $DotfilesRoot "topgrade.toml")

$wingetStateDirectory = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState"
New-Item -ItemType Directory -Path $wingetStateDirectory -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $DotfilesRoot "winget-settings.json") -Destination (Join-Path $wingetStateDirectory "settings.json") -Force

$terminalPackagesDirectory = Join-Path $env:LOCALAPPDATA "Packages"
$terminalPackageNames = @(
    "Microsoft.WindowsTerminal_8wekyb3d8bbwe",
    "Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe"
)

foreach ($packageName in $terminalPackageNames) {
    $packageDirectory = Join-Path $terminalPackagesDirectory $packageName
    if (Test-Path -LiteralPath $packageDirectory -PathType Container) {
        $localStateDirectory = Join-Path $packageDirectory "LocalState"
        New-Item -ItemType Directory -Path $localStateDirectory -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $DotfilesRoot "terminal.json") -Destination (Join-Path $localStateDirectory "settings.json") -Force
    }
}

switch ($env:COMPUTERNAME) {
    "RyzenBox" {
        $memoryGb = 16
        $kernel = "C:\\bzImage-zen3"
        $kernelModules = "C:\\bzImage-zen3-addons.vhdx"
    }
    "GroundBox" {
        $memoryGb = 4
        $kernel = "C:\\bzImage-x64v3"
        $kernelModules = "C:\\bzImage-x64v3-addons.vhdx"
    }
    default {
        $totalMemoryGb = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB
        $memoryGb = [Math]::Max(4, [Math]::Floor($totalMemoryGb / 2))
        $kernel = "C:\\bzImage-x64v3"
        $kernelModules = "C:\\bzImage-x64v3-addons.vhdx"
    }
}

$wslConfig = @"
[wsl2]
memory=${memoryGb}GB
kernel=$kernel
kernelModules=$kernelModules

swap=0
nestedVirtualization=false
hardwarePerformanceCounters=false
dnsTunneling=true
firewall=true

[experimental]
autoMemoryReclaim=dropcache
sparseVhd=true
hostAddressLoopback=true
"@

$wslConfigPath = Join-Path $env:USERPROFILE ".wslconfig"
Set-Content -LiteralPath $wslConfigPath -Value $wslConfig -Encoding UTF8
