[CmdletBinding()]
param(
    [string]$LauncherPath = "D:\REPENTOGON\REPENTOGONLauncher.exe",
    [string]$GamePath = "D:\SteamLibrary\steamapps\common\The Binding of Isaac Rebirth\Repentogon\isaac-ng.exe",
    [string]$PatchedDllPath = (Join-Path $PSScriptRoot "native\bin\zhlREPENTOGON.dll"),
    [string]$TargetDllPath = "D:\SteamLibrary\steamapps\common\The Binding of Isaac Rebirth\Repentogon\zhlREPENTOGON.dll",
    [int]$PollMilliseconds = 120,
    [int]$MaxWatchSeconds = 600,
    [switch]$DirectGame
)

$ErrorActionPreference = "Stop"

function Get-Sha256([string]$path) {
    if (-not (Test-Path $path)) {
        return ""
    }
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        try {
            return (Get-FileHash -Path $path -Algorithm SHA256 -ErrorAction Stop).Hash
        }
        catch {
            if ($attempt -eq 5) {
                return "LOCKED"
            }
            Start-Sleep -Milliseconds 100
        }
    }
    return ""
}

if (-not (Test-Path $LauncherPath)) {
    throw "Launcher not found: $LauncherPath"
}
if (-not (Test-Path $GamePath)) {
    throw "Game executable not found: $GamePath"
}
if (-not (Test-Path $PatchedDllPath)) {
    throw "Patched DLL not found: $PatchedDllPath"
}
if (-not (Test-Path $TargetDllPath)) {
    throw "Target DLL not found: $TargetDllPath"
}

$targetDir = Split-Path -Parent $TargetDllPath
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = Join-Path $targetDir ("zhlREPENTOGON.dll.bak-prelaunch-" + $stamp)

Copy-Item -Path $TargetDllPath -Destination $backupPath -Force
Copy-Item -Path $PatchedDllPath -Destination $TargetDllPath -Force

$patchedHash = Get-Sha256 $PatchedDllPath
$currentHash = Get-Sha256 $TargetDllPath
if ($patchedHash -ne $currentHash) {
    throw "Initial copy mismatch. Patched hash does not match target hash."
}

Write-Host "Patched DLL hash: $patchedHash"
Write-Host "Initial backup: $backupPath"
if ($DirectGame) {
    Write-Host "Starting game directly (unsupported by REPENTOGON); updater is bypassed."
    $processPath = $GamePath
    $workingDirectory = Split-Path -Parent $GamePath
}
else {
    Write-Host "Starting REPENTOGON launcher and enforcing patched DLL during startup..."
    $processPath = $LauncherPath
    $workingDirectory = Split-Path -Parent $LauncherPath
}

$launcher = Start-Process -FilePath $processPath -WorkingDirectory $workingDirectory -PassThru
$deadline = (Get-Date).AddSeconds($MaxWatchSeconds)
$repairedCount = 0

while (-not $launcher.HasExited -and (Get-Date) -lt $deadline) {
    $targetHash = Get-Sha256 $TargetDllPath
    if ($targetHash -ne $patchedHash) {
        try {
            Copy-Item -Path $PatchedDllPath -Destination $TargetDllPath -Force
            $repairedCount++
            Write-Host "[$(Get-Date -Format HH:mm:ss)] Replaced overwritten DLL ($repairedCount)."
        }
        catch {
            Write-Host "[$(Get-Date -Format HH:mm:ss)] Copy failed (likely file lock if game already loaded)."
        }
    }

    Start-Sleep -Milliseconds $PollMilliseconds
    $launcher.Refresh()
}

$finalHash = Get-Sha256 $TargetDllPath
$hashMatch = ($finalHash -eq $patchedHash)

Write-Host "Process exited: $($launcher.HasExited)"
Write-Host "Final target hash: $finalHash"
Write-Host "Hash match with patched DLL: $hashMatch"

if (-not $hashMatch) {
    Write-Warning "Target DLL differs from patched build after launcher run. Re-run this script and launch game immediately."
}
