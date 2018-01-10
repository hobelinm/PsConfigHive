<#
.SYNOPSIS
Set a value override for a config hive

.DESCRIPTION
Sets a value for a specified configuration hive. This value can be used to override lower level values. By default the
highest level is used (Session) unless specified otherwise

.EXAMPLE
$now = Get-Date
Set-ConfigValue -Key 'Test' -Value $now -HiveName 'Test'

Sets a value for registered hive 'Test' for default level store 'Session'

.EXAMPLE
Set-ConfigValue -Key 'Origin' -Value 'Origin' -HiveName 'Test' -Level 'Origin'

Sets a config value for 'Test' config hive for 'Origin' level

.EXAMPLE
Set-ConfigValue -Key 'System' -Value 'System' -HiveName 'Test' -Level 'System'

Sets a config value for 'Test' config hive for 'System' level

.EXAMPLE
Set-ConfigValue -Key 'User' -Value 'User' -HiveName 'Test' -Level 'User'

Sets a config value for 'Test' config hive for 'User' level

.EXAMPLE
Set-ConfigValue -Key 'Session' -Value 'Session' -HiveName 'Test' -Level 'Session'

Sets a config value for 'Test' config hive for 'Session' level

.NOTES
The value will be stored by the store, depending on the store implementation used, the value can be serialized and this
might cause certain issues specially with complex data types
Certain operations might require admin privileges. In particular System, Origin level stores on CliFileStore are known
for this requirement

#>

function Set-ConfigValue {
  [CmdletBinding()]
  param(
    # Key to associate the value with
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Key,

    # Value to store
    [Parameter(Mandatory)]
    $Value,

    # Name of the hive that will store the values
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $HiveName,

    [Parameter()]
    [CacheStoreLevel] $Level = [CacheStoreLevel]::Session
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
  $store.SetValue($Key, $Value)
}
