param(
    [string]$GamePath = "D:\SteamLibrary\steamapps\common\The Binding of Isaac Rebirth"
)

$sourcePath = $PSScriptRoot
$modsPath = Join-Path $GamePath "mods"
$destinationPath = Join-Path $modsPath "item_priority_manager"

if (-not (Test-Path $modsPath)) {
    throw "Isaac mods directory was not found: $modsPath"
}

New-Item -ItemType Directory -Force -Path $destinationPath | Out-Null
Copy-Item -Path (Join-Path $sourcePath "main.lua") -Destination $destinationPath -Force
Copy-Item -Path (Join-Path $sourcePath "metadata.xml") -Destination $destinationPath -Force
$scriptsSourcePath = Join-Path $sourcePath "scripts"
$scriptsDestinationPath = Join-Path $destinationPath "scripts"
New-Item -ItemType Directory -Force -Path $scriptsDestinationPath | Out-Null
Copy-Item -Path (Join-Path $scriptsSourcePath "*") -Destination $scriptsDestinationPath -Recurse -Force

Write-Output "Deployed Item Priority Manager to: $destinationPath"