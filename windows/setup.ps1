[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [System.Security.Principal.WindowsPrincipal]::new($currentIdentity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    & $FilePath @Arguments

    if ($LASTEXITCODE -ne 0) {
        $joinedArguments = $Arguments -join " "
        throw "$FilePath failed with exit code ${LASTEXITCODE}: $FilePath $joinedArguments"
    }
}

function Get-DscCommandPath {
    $dscCommand = Get-Command -Name dsc -ErrorAction SilentlyContinue
    if ($dscCommand) {
        return $dscCommand.Source
    }

    $windowsAppsDsc = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Microsoft\WindowsApps\dsc.exe"
    if (Test-Path -LiteralPath $windowsAppsDsc) {
        return $windowsAppsDsc
    }

    return $null
}

function Install-DscWithWinget {
    $wingetCommand = Get-Command -Name winget -ErrorAction SilentlyContinue
    if (-not $wingetCommand) {
        throw "The 'winget' CLI was not found, so DSC v3 cannot be bootstrapped automatically."
    }

    Write-Host "Installing DSC v3 with winget..."
    Invoke-NativeCommand -FilePath $wingetCommand.Source -Arguments @(
        "install",
        "--id",
        "Microsoft.DSC",
        "--exact",
        "--accept-package-agreements",
        "--accept-source-agreements",
        "--disable-interactivity"
    )

    $env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
        [System.Environment]::GetEnvironmentVariable("Path", "User")

    $dscCommandPath = Get-DscCommandPath
    if (-not $dscCommandPath) {
        throw "DSC v3 was installed, but dsc.exe was not resolvable in the current session."
    }

    return $dscCommandPath
}

function Disable-StoreSearchSuggestions {
    $storeDbPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState\store.db"

    if (-not (Test-Path -LiteralPath $storeDbPath)) {
        Write-Warning "Skipping Microsoft Store search suggestion tweak because the Store database was not found: $storeDbPath"
        return
    }

    Write-Host "Blocking Microsoft Store search suggestions..."
    Invoke-NativeCommand -FilePath "icacls.exe" -Arguments @(
        $storeDbPath,
        "/deny",
        "Everyone:F"
    )
}

if (-not (Test-IsAdministrator)) {
    throw "Run this script from an elevated PowerShell session."
}

$ownershipScript = Join-Path -Path $PSScriptRoot -ChildPath "take_ownership_downloads_foldertype.ps1"
$dscConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "registry.dsc.yaml"
$dscCommandPath = Get-DscCommandPath

if (-not (Test-Path -LiteralPath $ownershipScript)) {
    throw "Missing helper script: $ownershipScript"
}

if (-not $dscCommandPath) {
    $dscCommandPath = Install-DscWithWinget
}

if (-not (Test-Path -LiteralPath $dscConfigFile)) {
    throw "Missing DSC config file: $dscConfigFile"
}

Write-Host "Taking ownership of Downloads folder type keys..."
& $ownershipScript

Write-Host "Applying registry state with DSC v3..."
Invoke-NativeCommand -FilePath $dscCommandPath -Arguments @("config", "set", "--file", $dscConfigFile)

Disable-StoreSearchSuggestions

Write-Host "Windows setup changes applied. Restart Explorer or sign out to pick up the folder view change."
