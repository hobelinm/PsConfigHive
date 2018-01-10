<#
.SYNOPSIS
Initialize or re-initialize a given store or a store for a given registered Hive Config

.DESCRIPTION
Seed data into a store passed by the user or a store of an existing Hive Config

.EXAMPLE
$data = @{}
$data['MyKey1'] = 'MyVal1'
$data['MyKey2'] = 'MyVal2'
Initialize-DataStore -HiveName 'MyConfigHive' -Level 'Origin' -Data $data

Seeds store at 'Origin' level for registered hive 'MyConfigHive' with the given data

.EXAMPLE
$data = @{}
$data['MyKey1'] = 'MyVal1'
$data['MyKey2'] = 'MyVal2'
$myDataStore = New-DataStore -HiveName 'MyConfigHive' -StoreName 'MemStore' -StoreLevel 'Session'
Initialize-DataStore -CustomStore $myDataStore -Data $data

Seeds data for the newly created store

.NOTES
Certain operations might require admin privileges. In particular System, Origin level stores on CliFileStore are known
for this requirement

#>

function Initialize-DataStore {
  [CmdletBinding(DefaultParameterSetName = 'ExistingHive')]
  param(
    # Registered config hive to seed the value from
    [Parameter(Mandatory, ParameterSetName = 'ExistingHive')]
    [ValidateNotNullOrEmpty()]
    [string] $HiveName,

    # Store level within registered hive to set values
    [Parameter(Mandatory, ParameterSetName = 'ExistingHive')]
    [CacheStoreLevel] $Level,

    # Custom store to initialize
    [Parameter(Mandatory, ParameterSetName = 'CustomStore')]
    [ConfigBaseStore] $CustomStore,

    # Data used for initialization
    [Parameter(Mandatory, ParameterSetName = 'ExistingHive')]
    [Parameter(Mandatory, ParameterSetName = 'CustomStore')]
    [HashTable] $Data
  )

  $ErrorActionPreference = 'Stop'
  if ($CustomStore -eq $null) {
    $Data.Keys | ForEach-Object {
      $key = $_
      $value = $Data[$key]
      Set-ConfigValue -Key $key -Value $value -HiveName $HiveName -Level $Level
    }
  }
  else {
    $CustomStore.InitializeStore($Data)
    Write-Output $CustomStore
  }
}
