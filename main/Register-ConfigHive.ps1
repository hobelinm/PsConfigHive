<#
.SYNOPSIS
Registers a new config hive

.DESCRIPTION
Registers a new config hive outlining stores for different access levels. By default all stores used are based on one of
the two available store implementations shipped with the module which is MemStore.
These options are used unless changed by the user via parameters

.EXAMPLE
Register-ConfigHive -HiveName 'MyConfigHive'

Registers a configuration hive using default values

.EXAMPLE
Register-ConfigHive -HiveName 'MyConfigHive' -Force

Registers a configuration hive using default values overriding any previous registration

.EXAMPLE
$userStore = New-DataStore -HiveName 'Test' -StoreName 'CliFileStore' -StoreLevel 'User' -Options ([TimeSpan] '0:0:5')
Register-ConfigHive -HiveName 'Test' -UserStore $userStore

Creates a custom data store for User level using 'CliFileStore', this data store is then used for that particular level
for registering 'Test' config hive

.NOTES
Certain operations might require admin privileges. In particular System, Origin level stores on CliFileStore are known
for this requirement

#>

function Register-ConfigHive {
  [CmdletBinding()]
  param(
    # Name of the Config Hive
    [Parameter(Mandatory)]
    [Alias('Name')]
    [ValidateNotNullOrEmpty()]
    [string] $HiveName,

    # Store used manage original configuration data
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ConfigBaseStore] $OriginStore = $null,

    # Store used to manage system level configuration overrides
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ConfigBaseStore] $SystemStore = $null,

    # Store used to manage user level configuration overrides
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ConfigBaseStore] $UserStore = $null,

    # Store used to manage session level configuration overrides
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ConfigBaseStore] $SessionStore = $null,

    # Used to override existing registrations
    [Parameter()]
    [switch] $Force = $false
  )

  $ErrorActionPreference = 'Stop'
  $existinRegistrations = @(Get-RegisteredHives)
  if (($existinRegistrations -contains $HiveName) -and -not $Force) {
    $m = "A config hive with name '{0}' is already registered, use -Force to override" -f $HiveName
    $err = New-Object ConfigHiveError -ArgumentList 'DuplicateHiveName', $m
    throw($err)
  }

  if ($OriginStore -eq $null) {
    $OriginStore = New-DataStore -HiveName $HiveName -StoreName 'MemStore' -StoreLevel 'Origin'
  }

  if ($SystemStore -eq $null) {
    $SystemStore = New-DataStore -HiveName $HiveName -StoreName 'MemStore' -StoreLevel 'System'
  }

  if ($UserStore -eq $null) {
    $UserStore = New-DataStore -HiveName $HiveName -StoreName 'MemStore' -StoreLevel 'User'
  }

  if ($SessionStore -eq $null) {
    $SessionStore = New-DataStore -HiveName $HiveName -StoreName 'MemStore' -StoreLevel 'Session'
  }

  $hiveMeta = @{
    'HiveName' = $HiveName
    'Origin'   = $OriginStore
    'System'   = $SystemStore
    'User'     = $UserStore
    'Session'  = $SessionStore
  }
  
  $Script:ActiveConfigHives[$HiveName] = [PSCustomObject] $hiveMeta
  
  # Save the registration to disk
  $serializedHiveMeta = @{
    'HiveName'    = $HiveName
    'OriginName'  = $OriginStore.StoreName
    'OriginData'  = $OriginStore.SerializeInstanceData()
    'SystemName'  = $SystemStore.StoreName
    'SystemData'  = $SystemStore.SerializeInstanceData()
    'UserName'    = $UserStore.StoreName
    'UserData'    = $UserStore.SerializeInstanceData()
    'SessionName' = $SessionStore.StoreName
    'SessionData' = $SessionStore.SerializeInstanceData()
  }

  $hiveMetaPath = Get-HiveMetaPath
  $hiveMetaFile = Join-Path -Path $hiveMetaPath -ChildPath ("{0}.xml" -f $HiveName)
  $policy = New-RetryPolicy -Policy Random -Milliseconds 5000 -Retries 3
  Invoke-ScriptBlockWithRetry -Context { $serializedHiveMeta | Export-Clixml -Path $hiveMetaFile } -RetryPolicy $policy
}
