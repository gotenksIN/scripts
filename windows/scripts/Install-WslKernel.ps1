[CmdletBinding()]
param(
    [string]$DestinationDirectory = "C:\",
    [string]$Architecture = "x64v3",
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$DestinationDirectory = (Resolve-Path -LiteralPath $DestinationDirectory).ProviderPath

$releaseUrl = "https://api.github.com/repos/Locietta/xanmod-kernel-WSL2/releases/latest"
Write-Host "Fetching latest XanMod WSL2 kernel release metadata..."
$release = Invoke-RestMethod -Uri $releaseUrl -Headers @{ "User-Agent" = "PowerShell" }

$kernelName = "bzImage-$Architecture"
$addonsArchiveName = "bzImage-$Architecture-addons.vhdx.7z"
$addonsFileName = "bzImage-$Architecture-addons.vhdx"

$kernelAsset = $release.assets | Where-Object { $_.name -eq $kernelName }
$addonsAsset = $release.assets | Where-Object { $_.name -eq $addonsArchiveName }

if (-not $kernelAsset) {
    throw "Kernel asset '$kernelName' not found in release $($release.tag_name)."
}
if (-not $addonsAsset) {
    throw "Addons archive '$addonsArchiveName' not found in release $($release.tag_name)."
}

$kernelPath = Join-Path -Path $DestinationDirectory -ChildPath $kernelName
$addonsPath = Join-Path -Path $DestinationDirectory -ChildPath $addonsFileName

if (-not $Force -and (Test-Path -LiteralPath $kernelPath) -and (Test-Path -LiteralPath $addonsPath)) {
    $existingKernel = Get-Item -LiteralPath $kernelPath
    if ($existingKernel.Length -eq $kernelAsset.size) {
        Write-Host "Custom WSL2 kernel ($kernelName, $($release.tag_name)) is already up to date."
        return
    }
}

Write-Host "Installing XanMod WSL2 kernel $($release.tag_name) ($Architecture)..."

if (Get-Command -Name "wsl.exe" -ErrorAction SilentlyContinue) {
    $running = & wsl.exe --list --running 2>$null
    if ($running -and $running -notmatch "There are no running distributions") {
        Write-Host "Shutting down running WSL instances to release file locks..."
        & wsl.exe --shutdown
    }
}

$tempKernelPath = Join-Path -Path $env:TEMP -ChildPath "$kernelName.tmp"
$tempArchivePath = Join-Path -Path $env:TEMP -ChildPath $addonsArchiveName

try {
    Write-Host "Downloading $kernelName ($([Math]::Round($kernelAsset.size / 1MB, 2)) MB)..."
    Invoke-WebRequest -Uri $kernelAsset.browser_download_url -OutFile $tempKernelPath -UseBasicParsing

    Write-Host "Downloading $addonsArchiveName ($([Math]::Round($addonsAsset.size / 1MB, 2)) MB)..."
    Invoke-WebRequest -Uri $addonsAsset.browser_download_url -OutFile $tempArchivePath -UseBasicParsing

    Move-Item -LiteralPath $tempKernelPath -Destination $kernelPath -Force

    Write-Host "Extracting $addonsFileName to $DestinationDirectory..."
    $sevenZip = Get-Command -Name "7z.exe", "7z", "nanazip.exe", "nanazip" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($sevenZip) {
        & $sevenZip.Source x $tempArchivePath -o"$DestinationDirectory" -y | Out-Null
    } elseif (Get-Command -Name "tar.exe" -ErrorAction SilentlyContinue) {
        & tar.exe -xf $tempArchivePath -C $DestinationDirectory
    } else {
        throw "Neither 7-Zip/NanaZip nor tar.exe is available to extract $addonsArchiveName."
    }

    if (-not (Test-Path -LiteralPath $addonsPath)) {
        throw "Extraction completed but $addonsPath was not found."
    }

    Write-Host "Successfully installed $kernelName and $addonsFileName to $DestinationDirectory."
}
finally {
    if (Test-Path -LiteralPath $tempKernelPath) {
        Remove-Item -LiteralPath $tempKernelPath -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $tempArchivePath) {
        Remove-Item -LiteralPath $tempArchivePath -Force -ErrorAction SilentlyContinue
    }
}
