<#
.SYNOPSIS
Retrieves all values for a given configuration hive

.DESCRIPTION
Retrieves all values from all store levels and aggregate them applying higher levels as overrides

.EXAMPLE
Get-ConfigHive -HiveName 'MyConfigHive'

Retrieves all values and overrides for the registered hive 'MyConfigHive'

.NOTES
Certain operations might require admin privileges. In particular System, Origin level stores on CliFileStore are known
for this requirement

#>

function Get-ConfigHive {
  [CmdletBinding()]
  param(
    # Name of the configuration hive to retrieve data from
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $HiveName
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

  $hiveData = @{}
  $configHive = $Script:ActiveConfigHives[$HiveName]
  # Traverse levels low to high to apply overrides in the correct order
  @('Origin', 'System', 'User', 'Session') | ForEach-Object {
    $level = $_
    $store = [ConfigBaseStore] ($configHive.$level)
    $store.GetKeys() | ForEach-Object {
      $key = $_
      $hiveData[$key] = $store.GetValue($key).Value
    }
  }

  Write-Output $hiveData
}
