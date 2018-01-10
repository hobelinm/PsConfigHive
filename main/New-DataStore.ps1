<#
.SYNOPSIS
Creates instances of config stores

.DESCRIPTION
Creates specified config store for the provided Config Hive

.EXAMPLE
New-Datastore -HiveName 'Test' -StoreName 'MemStore' -StoreLevel 'Origin' 

Creates a new data store using in-memory implementation 'MemStore' for storing origin level configuration for the given
hive name

.EXAMPLE
New-DataStore -HiveName 'Test' 

According to the default values of this cmdlet it creates a 'MemStore' to store user level configuration for the given
hive name

.EXAMPLE
New-DataStore -HiveName 'Test' -StoreName 'MemStore' -StoreLevel 'System'

Creates a MemStore for System level access for the given hive name

.EXAMPLE
New-DataStore -HiveName 'Test' -StoreName 'MemStore' -StoreLevel 'Session'

Creates a MemStore for Session level configuration data for the given hive name

.EXAMPLE
New-DataStore -HiveName 'Test' -StoreName 'CliFileStore' -StoreLevel 'User' -Options ([TimeSpan] '0:0:5')

Creates a CLI serialized File store for User level configuration. This store requires custom parameters, the accepted
parameters are [TimeStamp] or [ScriptBlock] which basically allows to customize the caching policy for hitting the target
configuration file, every time the cache get invalidated access to the data will involve IO operation(s) to access the 
file otherwise cache data will be returned

.EXAMPLE
New-DataStore -HiveName 'Test' -StoreName 'CliFileStore' -StoreLevel 'System' -Options ([TimeSpan] '0:0:5')

Creates a CLI File store for System level configuration, since this operation allows the data to be accessible at a
system level, the running process must have access to the shared location designed, this typically requires admin
access to the system otherwise the instance of the new store and/or operations with it may fail, it is responsiblity
of the user to ensure the appropriate permission levels are used when using this option

.NOTES
Certain operations might require admin privileges. In particular System, Origin level stores on CliFileStore are known
for this requirement

#>

function New-DataStore {
  [CmdletBinding(DefaultParameterSetName = 'Normal')]
  param(
    # Config Hive to be used with
    [Parameter(Mandatory, ParameterSetName = 'Normal')]
    [Alias('Name')]
    [ValidateNotNullOrEmpty()]
    [string] $HiveName,

    # Name of the config store to create
    [Parameter(ParameterSetName = 'Normal')]
    [Parameter(ParameterSetName = 'Serialized')]
    [ValidateScript({$Script:AvailableStores -contains $_})]
    [string] $StoreName = 'MemStore',

    # Determines to what level is the store going to be used for
    [Parameter(ParameterSetName = 'Normal')]
    [CacheStoreLevel] $StoreLevel = 'User',

    # Allows to pass custom options to the store initialization
    [Parameter(ParameterSetName = 'Normal')]
    [ValidateNotNullOrEmpty()]
    $Options = $null,

    # Rehydrates a store based on serialized data
    [Parameter(Mandatory, ParameterSetName = 'Serialized')]
    [ValidateNotNullOrEmpty()]
    [string] $SerializedStoreData = [string]::Empty
  )

  $store = New-Object $StoreName

  if ($SerializedStoreData -ne [string]::Empty) {
    Write-Output $store.Rehydrate($SerializedStoreData)
  }
  else {
    $storeInstance = $store.NewInstance($HiveName, $StoreLevel)
    if ($storeInstance.RequiresCustomParams() -and $Options -eq $null) {
      $m = "Store of type '{0}' requires custom parameters" -f $StoreName
      $err = New-Object ConfigHiveError -ArgumentList 'InvalidArgument', $m
      throw($err)
    }
  
    if ($Options -ne $null) {
      $storeInstance.SetCustomParams($Options)
    }
  
    $serializedData = $storeInstance.SerializeInstanceData()
    if ($serializedData -eq [string]::Empty -or $serializedData -eq $null) {
      $m = "Store of type '{0}' does not implemente ConfigBaseStore properly" -f $StoreName
      $err = New-Object ConfigHiveError -ArgumentList 'InvalidImplementation', $m
      throw($err)
    }
  
    Write-Output $storeInstance
  }
}
