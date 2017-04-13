# PS Config Hive

$ErrorActionPreference = 'Stop'

# Load all cmdlets
$mainFolder = Join-Path -Path $PSScriptRoot -ChildPath "Main"
Get-ChildItem -Filter '*.ps1' -Recurse -Path $mainFolder | ForEach-Object {
    $moduleScript = $_.FullName
    . $moduleScript
}

# "bin": {"Ps-ConfigHive": "./start.bat"},
Write-Warning "Module Loaded!"

# Check if xUtility module is available and load it
