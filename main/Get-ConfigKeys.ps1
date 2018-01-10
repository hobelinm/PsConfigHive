<#
.SYNOPSIS
Gets the keys available for a given configuration hive

.DESCRIPTION
Gets available configuration keys for the given configuration hive, if Level is specified only they keys for the given
level are specified

.EXAMPLE
Get-ConfigKeys -HiveName 'MyConfigHive'

Returns keys for all store levels

.EXAMPLE
Get-ConfigKeys -HiveName 'MyConfigHive' -Level 'User'

Returns the keys stored at 'User' level/store

.NOTES
Certain operations might require admin privileges. In particular System, Origin level stores on CliFileStore are known
for this requirement

#>

function Get-ConfigKeys {
  [CmdletBinding()]
  param(
    # Name of the config hive to list keys from
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $HiveName,

    # Level to list keys from
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

    Write-Output $levelStore.GetKeys()
    return
  }

  $keys = @()
  @('Session', 'User', 'System', 'Origin') | ForEach-Object {
    $testLevel = $_
    $testStore = [ConfigBaseStore] ($configHive.$testLevel)
    $keys += $testStore.GetKeys()
  }

  Write-Output ($keys | Select-Object -Unique)
}
