<#
.SYNOPSIS
Gets a configuration value from a registered configuration hive

.DESCRIPTION
Gets a configuration value from a registered configuration hive. Returns the 'highest' override applied if no
level is specified. Level/Stores are checked in this order:
Session -> User -> System -> Origin

.EXAMPLE
Get-ConfigValue -Key 'myKey' -HiveName 'MyConfigHive'

Gets the highest override for the key 'myKey' for config hive 'MyConfigHive'

.EXAMPLE
Get-ConfigValue -Key 'myKey' -HiveName 'MyConfigHive' -Level 'System'

Gets the override at system level for the specified key and hive name

.NOTES
Certain operations might require admin privileges. In particular System, Origin level stores on CliFileStore are known
for this requirement

#>

function Get-ConfigValue {
  [CmdletBinding()]
  param(
    # Key of the value to retrieve
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Key,

    # Name of the configuration hive to retrieve the value from
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $HiveName,

    # Level to pick a specific override from
    [Parameter()]
    [CacheStoreLevel] $Level
  )

  $ErrorActionPreference = 'Stop'
  if ($Script:ActiveConfigHives[$HiveName] -eq $null) {
    # Attempt to load configuration hive metadata
    $metas = @(Get-RegisteredHives)
    if ($metas -notcontains $HiveName) {
      $m = "Configuration Hive named '{0}' was not found amongs registered configuration hives" -f $HiveName
      $err = New-Object ConfigHiveError -ArgumentList 'ConfigHiveNotFound', $m
      throw($err)
    }

    LoadHive -HiveName $HiveName
  }

  if ($Script:ActiveConfigHives[$HiveName] -eq $null) {
    $m = "Failed loading configuration hive: '{0}'" -f $HiveName
    $err = New-Object ConfigHiveError -ArgumentList 'ConfigHiveLoadFailure', $m
    throw($err)
  }

  $configHive = $Script:ActiveConfigHives[$HiveName]
  if ($Level -ne $null) {
    $levelProp = $Level.ToString()
    $levelStore = [ConfigBaseStore] ($configHive.$levelProp)
    if ($levelStore -eq $null) {
      $m = "Could not find suitable store implementation for specified level '{0}'" -f $Level
      $err = New-Object ConfigHiveError -ArgumentList 'StoreNotFound', $m
      throw($err)
    }

    if ($levelStore.GetKeys() -notcontains $Key) {
      $m = "Key '{0}' not found in config hive '{1}'" -f $Key, $HiveName
      $err = New-Object ConfigHiveError -ArgumentList 'KeyNotFound', $m
      throw($err)
    }

    Write-Output $levelStore.GetValue($Key).Value
    return
  }

  $processNext = $true
  # Traverse levels high to low to return highest override available
  @('Session', 'User', 'System', 'Origin') | Where-Object { $processNext } | ForEach-Object {
    $testLevel = $_
    $testStore = [ConfigBaseStore] ($configHive.$testLevel)
    if ($testStore.GetKeys() -contains $Key) {
      Write-Output ($testStore.GetValue($Key).Value)
      $processNext = $false
    }
  }

  if ($processNext) {
    $m = "Key '{0}' not found in config hive '{1}'" -f $Key, $HiveName
    $err = New-Object ConfigHiveError -ArgumentList 'KeyNotFound', $m
    throw($err)
  }
}
