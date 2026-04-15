<#
Fix-HEVC-AMF.ps1

Usage:
  .\Fix-HEVC-AMF.ps1 "Path\to\Folder" [-ValidateOutput]

Behavior
- ffmpeg shows normal console progress via -stats (frame/fps/speed).
- Only v:0 is re-encoded (hevc_amf). EVERYTHING else is copied (all audio/subs/attachments/chapters/metadata).
- Replaces original only on success (no backups).
- Skips already-processed names using: "<FinalFolderName>.txt" in the CURRENT directory.
- Logs failures to: "<FinalFolderName>.failed.txt" in the CURRENT directory.
#>

param(
  [Parameter(Mandatory=$true, Position=0)]
  [string]$Folder,

  [switch]$ValidateOutput,

  # Size-tuning knobs (leave defaults if you want)
  [double]$ShrinkFactor = 0.90,   # 0.90 helps keep output close to source size
  [double]$MaxRateFactor = 1.15,  # peak allowance
  [double]$BufFactor = 2.0        # VBV buffer factor
)

$folderPath = (Resolve-Path -LiteralPath $Folder).Path.TrimEnd('\')
$leaf = Split-Path -Leaf $folderPath

$processedList = Join-Path (Get-Location) ($leaf + ".txt")
$failedList    = Join-Path (Get-Location) ($leaf + ".failed.txt")

function Write-Status([string]$Message) {
  Write-Information $Message -InformationAction Continue
}

# Load processed file names (case-insensitive)
$processed = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
if (Test-Path -LiteralPath $processedList) {
  Get-Content -LiteralPath $processedList | ForEach-Object {
    $t = $_.Trim()
      if ($t) { [void]$processed.Add($t) }
  }
}

function Add-ProcessedEntry([string]$name) {
  Add-Content -LiteralPath $processedList -Value $name
  [void]$processed.Add($name)
}

function Add-FailureEntry([string]$name, [string]$reason) {
  $stamp = (Get-Date).ToString("s")
  Add-Content -LiteralPath $failedList -Value ("[{0}] {1} :: {2}" -f $stamp, $name, $reason)
}

# Clamp target video bitrate (bits/s)
$MIN_VBR = 1500000
$MAX_VBR = 25000000

Write-Status "Input folder    : $folderPath"
Write-Status "Processed list  : $processedList"
Write-Status "Failed list     : $failedList"
Write-Status "ShrinkFactor    : $ShrinkFactor"
Write-Status "MaxRateFactor   : $MaxRateFactor"
Write-Status "BufFactor       : $BufFactor"
Write-Status "ValidateOutput  : $($ValidateOutput.IsPresent)"
Write-Status ""

Get-ChildItem -LiteralPath $folderPath -Filter *.mkv -File | ForEach-Object {

  $name = $_.Name
  $in   = $_.FullName
  $tmp  = Join-Path $_.DirectoryName ($_.BaseName + ".tmp.mkv")
  $nv   = Join-Path $_.DirectoryName ($_.BaseName + ".nonvideo.tmp.mkv")

  if ($processed.Contains($name)) {
    Write-Status "SKIP (already processed): $name"
    return
  }

  Write-Status ""
  Write-Status "=== Processing: $name ==="

  # Duration
  $durStr = & ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 $in
  $durStr = ($durStr | Select-Object -First 1).Trim()
  $dur = 0.0
  [void][double]::TryParse($durStr, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$dur)
  if ($dur -le 0) {
    Write-Warning "Can't read duration; skipping."
    Add-FailureEntry $name "ffprobe duration unreadable"
    return
  }

  # Build non-video probe (copy everything except video) to estimate non-video bytes accurately
  if (Test-Path -LiteralPath $nv) { Remove-Item -LiteralPath $nv -Force }
  & ffmpeg -y -hide_banner -loglevel warning -nostdin `
    -i $in -map 0 -map -0:v -c copy $nv

  if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $nv)) {
    Write-Warning "Failed to create non-video probe; skipping."
    Add-FailureEntry $name ("nonvideo probe failed (exitcode={0})" -f $LASTEXITCODE)
    if (Test-Path -LiteralPath $nv) { Remove-Item -LiteralPath $nv -Force }
    return
  }

  $totalBytes    = [int64]$_.Length
  $nonVideoBytes = [int64](Get-Item -LiteralPath $nv).Length
  Remove-Item -LiteralPath $nv -Force

  $totalBps    = [int64](($totalBytes * 8) / $dur)
  $nonVideoBps = [int64](($nonVideoBytes * 8) / $dur)
  $vBps        = [int64](($totalBps - $nonVideoBps) * $ShrinkFactor)

  $vBps = [int64]([Math]::Max($MIN_VBR, [Math]::Min($vBps, $MAX_VBR)))

  $vKbps   = [int]($vBps / 1000)
  $maxKbps = [int]([Math]::Ceiling($vKbps * $MaxRateFactor))
  $bufKbps = [int]([Math]::Ceiling($maxKbps * $BufFactor))

  Write-Status ("Target video bitrate: {0} kb/s (max {1} kb/s, buf {2} kb/s)" -f $vKbps, $maxKbps, $bufKbps)

  if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }

  # MAIN ENCODE: show the same progress style as before
  & ffmpeg -y -hide_banner -stats -nostdin `
    -hwaccel d3d11va -hwaccel_output_format nv12 -extra_hw_frames 32 `
    -i $in `
    -map 0 -map_metadata 0 `
    -c copy `
    -c:v:0 hevc_amf -profile:v main -usage transcoding -quality balanced `
    -rc vbr_peak -b:v:0 ("{0}k" -f $vKbps) -maxrate:v:0 ("{0}k" -f $maxKbps) -bufsize:v:0 ("{0}k" -f $bufKbps) `
    -preanalysis 0 -preencode 0 `
    $tmp

  if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $tmp)) {
    Write-Warning "Transcode failed; original kept."
    Add-FailureEntry $name ("encode failed (exitcode={0})" -f $LASTEXITCODE)
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
    return
  }

  if ($ValidateOutput.IsPresent) {
    Write-Status "Validating output (decode video to null)..."
    & ffmpeg -hide_banner -v error -nostdin -i $tmp -map 0:v:0 -an -f null - | Out-Null
    if ($LASTEXITCODE -ne 0) {
      Write-Warning "Validation failed; original kept."
      Add-FailureEntry $name ("validation failed (exitcode={0})" -f $LASTEXITCODE)
      Remove-Item -LiteralPath $tmp -Force
      return
    }
  }

  # Replace original (no backups)
  try {
    Move-Item -LiteralPath $tmp -Destination $in -Force -ErrorAction Stop
  }
  catch {
    Write-Warning "Replace failed; original kept if possible."
    Add-FailureEntry $name ("replace failed ({0})" -f $_.Exception.Message)
    return
  }

  Write-Status "Replaced OK."
  Add-ProcessedEntry $name
}
