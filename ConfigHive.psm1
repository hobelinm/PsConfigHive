$ErrorActionPreference = 'Stop'

# Global variables
$Script:ModuleLoadComplete = $false
$Script:ModuleHome = $PSScriptRoot
$Script:AvailableStores = @()
$Script:ActiveConfigHives = @{}

$mainFolder = Join-Path -Path $PSScriptRoot -ChildPath "main"
# Load Utilities and configuration first
. (Join-Path -Path $mainFolder -ChildPath 'util.ps1')
. (Join-Path -Path $mainFolder -ChildPath 'ConfigHiveError.ps1')
. (Join-Path -Path $mainFolder -ChildPath 'config.ps1')
. (Join-Path -Path $mainFolder -ChildPath 'stores/ConfigBaseStore.ps1')

# Module dependencies
$dependMods = GetConfig('Module.Dependencies')
$dependMods | ForEach-Object {
  $modName = $_
  $curMod = Get-Module -Name $modName
  if ($curMod -eq $null) {
    $curMod = Get-Module -Name $modName -ListAvailable
    if ($curMod -eq $null) {
      # The module needs to be installed
      Print -Message ("About to install module '{0}'" -f $modName)
      Install-Module -Name $modName -Scope CurrentUser
    }
    else {
      Import-Module $modName
    }
  }
}

# Load cmdlets
$skipFileList = @()
$skipFileList += 'config'
$skipFileList += 'ConfigBaseStore'
$skipFileList += 'ConfigHiveError'
$skipFileList += 'util'

# Load all stores
$storesPath = Join-Path -Path $mainFolder -ChildPath 'stores'
Get-ChildItem -Filter '*.ps1' -Recurse -Path $storesPath | Where-Object {
  $_.BaseName -ne 'ConfigBaseStore'
} | ForEach-Object {
  $storeScript = $_.FullName
  . $storeScript
  $skipFileList += $_.BaseName
}

# Load remaining cmdlets
Get-ChildItem -Filter '*.ps1' -Recurse -Path $mainFolder | Where-Object {
  $skipFileList.Contains($_.BaseName) -eq $false
} | ForEach-Object {
  $moduleScript = $_.FullName
  . $moduleScript
}

# Print load message
Write-Host '' # Inject a new line
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
Get-ChildItem -Path $storesPath | Where-Object { $_.PSIsContainer -eq $true } | ForEach-Object {
  $customStore = $_
  Print -Message $customStore.Name
  Get-ChildItem -Path $customStore.FullName -Filter '*.ps1' | ForEach-Object {
    $storeFile = $_.FullName
    . $storeFile
  }
}

Print -Message 'Loading Custom Stores... ' -NoNewLine
Write-Host 'DONE' -ForegroundColor Green

# Self register ConfigHive store
if (@(Get-RegisteredHives) -notcontains 'ConfigHive') {
  # By default ConfigHive will consist of in-memory data stores for every level except for User level
  $userLevel = New-DataStore -HiveName 'ConfigHive' -StoreName 'CliFileStore' -StoreLevel 'User' -Options ([TimeSpan] '0:0:5')
  Register-ConfigHive -HiveName 'ConfigHive' -UserStore $userLevel
}

# Seed ConfigHive Origin store
Initialize-DataStore -HiveName 'ConfigHive' -Level 'Origin' -Data $Script:BaseConfigOverridable

# TODO: Check for updates

$Script:ModuleLoadComplete = $true
