<#
.SYNOPSIS
Removes a value from a Config Hive Level

.DESCRIPTION
Removes a value from a Config Hive previously registered at a particular level

.EXAMPLE
Remove-ConfigValue -Key 'myKey' -HiveName 'MyConfigHive' -Level 'User'

Removes the value under 'myKey' for the given config hive at the specified level

.NOTES
Certain operations might require admin privileges. In particular System, Origin level stores on CliFileStore are known
for this requirement

#>

function Remove-ConfigValue {
  [CmdletBinding()]
  param(
    # Key entry to remove
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Key,

    # Hive to remove the entry from
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $HiveName,

    # Store level to remove the value from
    [Parameter(Mandatory)]
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
  $levelProp = $Level.ToString()
  if ($configHive.$levelProp -eq $null) {
    $m = "Could not find suitable store implementation for specified level '{0}'" -f $Level
    $err = New-Object ConfigHiveError -ArgumentList 'StoreNotFound', $m
    throw($err)
  }

  $store = [ConfigBaseStore] $configHive.$levelProp
  $store.RemoveValue($Key)
}
