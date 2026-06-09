[CmdletBinding()]
param(
    [string]$VMName = "WindowsDevTest",
    [string]$VHDPath = "C:\VMs\WindowsDevTest\WindowsDevTest.vhdx",
    [int]$MemoryGB = 4,
    [int]$CPUCount = 4,
    [string]$SwitchName = "Default Switch"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [System.Security.Principal.WindowsPrincipal]::new($currentIdentity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    Write-Error "This script must be run as an Administrator."
    exit 1
}

# Ensure Hyper-V feature is enabled on the host
if (-not (Get-Command -Name Get-VM -ErrorAction SilentlyContinue)) {
    Write-Host "Hyper-V commands are not available on this machine."
    Write-Host "Please ensure Hyper-V is enabled by running: Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All"
    exit 1
}

# Determine VHDX directory and ensure it exists
$vhdDir = Split-Path -Path $VHDPath -Parent
if (-not (Test-Path -Path $vhdDir)) {
    Write-Host "Creating directory: $vhdDir"
    New-Item -ItemType Directory -Path $vhdDir -Force | Out-Null
}

# Check if VM already exists
if (Get-VM -Name $VMName -ErrorAction SilentlyContinue) {
    Write-Host "VM with name '$VMName' already exists. Use another name or remove the existing VM first."
    exit 0
}

# Create new VHDX if it doesn't exist
if (-not (Test-Path -Path $VHDPath)) {
    Write-Host "Creating dynamic virtual hard disk of size 64GB at $VHDPath..."
    New-VHD -Path $VHDPath -SizeBytes 64GB -Dynamic | Out-Null
}

Write-Host "Creating Gen 2 Hyper-V Virtual Machine '$VMName'..."
$vm = New-VM -Name $VMName -MemoryStartupBytes ($MemoryGB * 1GB) -Generation 2 -VHDPath $VHDPath -SwitchName $SwitchName

Write-Host "Configuring VM processors and exposing virtualization extensions (for nested WSL2)..."
Set-VMProcessor -VMName $VMName -Count $CPUCount -ExposeVirtualizationExtensions $true

Write-Host "Configuring VM memory settings..."
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true -MinimumBytes (2GB) -StartupBytes ($MemoryGB * 1GB) -MaximumBytes ($MemoryGB * 1GB * 2)

Write-Host "Configuring firmware to enable Secure Boot..."
Set-VMFirmware -VMName $VMName -EnableSecureBoot On

Write-Host "Virtual machine '$VMName' created successfully."
Write-Host ""
Write-Host "To complete Windows 11 installation:"
Write-Host "1. Mount a Windows 11 ISO by running:"
Write-Host "   Set-VMDvdDrive -VMName '$VMName' -Path 'C:\path\to\windows11.iso'"
Write-Host "2. Start the virtual machine:"
Write-Host "   Start-VM -VMName '$VMName'"
Write-Host "3. Connect to the virtual machine using Hyper-V Manager or VMConnect."
