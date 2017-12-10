$ErrorActionPreference = 'Stop'

# Global variables
$Script:ModuleLoadComplete = $false
$Script:ModuleHome = $PSScriptRoot

$mainFolder = Join-Path -Path $PSScriptRoot -ChildPath "Main"
# Load Utilities and configuration first
. (Join-Path -Path $mainFolder -ChildPath 'util.ps1')
. (Join-Path -Path $mainFolder -ChildPath 'ConfigHiveError.ps1')
. (Join-Path -Path $mainFolder -ChildPath 'config.ps1')
. (Join-Path -Path $mainFolder -ChildPath 'stores/ConfigBaseStore.ps1')

$workPath = GetConfig('Module.WorkPath')
if (-not (Test-Path $workPath)) {
    New-Item -ItemType Directory -Path $workPath | Write-Verbose
}

# Load cmdlets
$skipFileList = @()
$skipFileList += 'config'
$skipFileList += 'ConfigBaseStore'
$skipFileList += 'ConfigHiveError'
$skipFileList += 'util'

# Load all cmdlets
Get-ChildItem -Filter '*.ps1' -Recurse -Path $mainFolder | Where-Object {
  $skipFileList.Contains($_.BaseName) -eq $false
} | ForEach-Object {
  $moduleScript = $_.FullName
  . $moduleScript
}

# Print load message
Print -Message 'ConfigHive v' -NoNewLine
$mVersion = (GetConfig('Module.Version')).ToString().Split('.')
$idx = 0
$mVersion | ForEach-Object {
  $digit = $_
  Write-Host $digit -NoNewline -ForegroundColor Green
  if ($idx -lt ($mVersion.Count - 1)) {
    Write-Host '.' -NoNewline
  }

  $idx++
}

Write-Host '' # Add CR/NL after the version message

# Load external store implementations
Print -Message 'Loading Custom Stores...'

$storesPath = Get-StorePath
Get-ChildItem -Filter '*.ps1' -Recurse -Path $storesPath | ForEach-Object {
    $storeScript = $_.FullName
    . $storeScript
}

Print -Message 'Loading Custom Stores... ' -NoNewLine
Write-Host 'DONE' -ForegroundColor Green


# Check if xUtility module is available and load it
# otherwise install it

$Script:ModuleLoadComplete = $true
