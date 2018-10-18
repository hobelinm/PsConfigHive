# Pretty print
function Print {
  [CmdletBinding()]
  param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $Header = [string]::Empty,

    [Parameter(Mandatory)]
    [string] $Message,

    [Parameter()]
    [System.ConsoleColor] $Accent = (GetConfig('Module.AccentColor')),

    [Parameter()]
    [System.ConsoleColor] $MessageColor,

    [Parameter()]
    [switch] $NoNewLine = $false
  )

  Write-Host '[' -NoNewline
  $caller = '<ScriptBlock>'
  if ($Header -ne [string]::Empty) {
    Write-Host $Header -ForegroundColor $Accent -NoNewline
  }
  else {
    Write-Host (GetConfig('Module.BaseName')) -ForegroundColor $Accent -NoNewline
    $caller = (Get-PSCallStack)[1].FunctionName
    
    if ($caller -ne '<ScriptBlock>') {
      Write-Host '.' -NoNewline
      Write-Host $caller -ForegroundColor $Accent -NoNewline
    }
  }
  
  $p = @{
    'Object'          = "] $Message"
    'NoNewLine'       = $NoNewLine
  }

  if ($MessageColor -ne $null) {
    Write-Host '] ' -NoNewline
    $p['Object'] = $Message
    $p['ForegroundColor'] = $MessageColor
  }

  Write-Host @p
}

# Pretty warn
function Warn {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
  )

  $p = @{
    'Accent'       = 'Yellow'
    'MessageColor' = 'Yellow'
    'Message'      = 'Warning: '
    'NoNewLine'    = $true
  }

  $caller = (Get-PSCallStack)[1].FunctionName
  if ($caller -ne '<ScriptBlock>') {
    $header = GetConfig('Module.BaseName')
    $header = "{0}.{1}" -f $header, $caller
    $p['Header'] = $header
  }

  Print @p
  Write-Host $Message
}

# Gets temp path according to the host
function Get-TempPath {
  [CmdletBinding()]
  param(
    [Parameter()]
    [switch] $BasePath = $false
  )

  $location = ''
  if (isWindows) {
    $location = $env:TEMP
  }
  else {
    $location = $env:TMPDIR
    if ($location -eq $null -or -not (Test-Path $location)) {
      $location = '/tmp'
    }
  }

  if ($BasePath) {
    Write-Output $location
  }
  else {
    $baseName = GetConfig('Module.BaseName')
    $location = Join-Path -Path $location -ChildPath $baseName
    if (-not (Test-Path $location)) {
      New-Item -ItemType Directory -Path $location | Write-Verbose
    }
  
    Write-Output $location
  }
}

# Returns the app data directory for each OS
function GetAppDataPath {
  [CmdletBinding()]
  param(
    [Parameter()]
    [switch] $BasePath = $false
  )
    
  $location = ''
  if (isWindows) {
    $location = $env:LOCALAPPDATA
  }
  else {
    $location = '~/Library/Preferences/'
    if ($location -eq $null -or -not (Test-Path $location)) {
      $location = '~/.local/share/'
    }
  }
  
  if (-not $BasePath) {
    $baseName = 'ConfigHive'
    $location = Join-Path -Path $location -ChildPath $baseName
    if (-not (Test-Path $location)) {
      New-Item -ItemType Directory -Path $location | Write-Verbose
    }
  }
  
  Write-Output $location
}

# Gets the path of the Hive Metadata
function Get-HiveMetaPath {
  [CmdletBinding()]
  param()

  $localAppData = GetAppDataPath
  $metasDirectory = 'HiveMeta'
  $metasPath = Join-Path -Path $localAppData -ChildPath $metasDirectory
  if (-not (Test-Path $metasPath)) {
    New-Item -ItemType Directory -Path $metasPath | Write-Verbose
  }

  Write-Output $metasPath
}

# Gets Program Data folder
function Get-ProgramDataPath {
  [CmdletBinding()]
  param()

  $ErrorActionPreference = 'Stop'
  $location = ''
  if (isWindows) {
    $location = $env:ProgramData
    if ($location -eq $null) {
      $location = Join-Path -Path $env:HOMEDRIVE -ChildPath 'ProgramData'
    }
  }
  else {
    $location = '/var/lib/'
  }

  $baseName = 'ConfigHive'
  $location = Join-Path -Path $location -ChildPath $baseName
  if (-not (Test-Path $location)) {
    New-Item -ItemType Directory -Path $location | Write-Verbose
  }

  Write-Output $location
}

# Gets the location of the implemented stores
function Get-StorePath {
  [CmdletBinding()]
  param()

  $ErrorActionPreference = 'Stop'
  $appData = GetAppDataPath
  $storePathFolder = GetConfig('Module.StorePath.BaseName')
  $storesPath = Join-Path -Path $appData -ChildPath $storePathFolder
  if (-not (Test-Path $storesPath)) {
    New-Item -ItemType Directory -Path $storesPath | Write-Verbose
  }

  Write-Output $storesPath
}

# Utils to determine the OS
function isWindows {
  [CmdletBinding()]
  param()

  if ($null -eq $PSVersionTable.OS -or $PSVersionTable.OS.Contains('Windows')) {
    Write-Output $true
  }
  else {
    Write-Output $false
  }
}

function isLinux {
  [CmdletBinding()]
  param()

  if ($PSVersionTable -eq $null) {
    Write-Output $false
    return
  }

  if ($PSVersionTable.OS -match 'Linux') {
    Write-Output $true
    return
  }

  Write-Output $false
}

# Module configuration reader
function GetConfig {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string] $Key
  )

  $ErrorActionPreference = 'Stop'
  # Check first on non-overridable defaults
  $constConfig = [HashTable] $Script:DefaultConfig
  if ($constConfig.Keys -contains $Key) {
    Write-Output $constConfig[$Key]
  }
  elseif ($Script:ModuleLoadComplete -eq $true) {
    # Use service if we have user configurable options if available
    Write-Output (Get-ConfigValue -Key $Key -HiveName 'ConfigHive')
  }
  else {
    # otherwise use default overridable options
    $baseConfig = [HashTable] $Script:BaseConfigOverridable
    Write-Output $baseConfig[$Key]
  }
}

# Loads a configuration hive from metadata
function LoadHive {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $HiveName
  )

  $ErrorActionPreference = 'Stop'
  $hivesMeta = Get-HiveMetaPath
  $targetHiveMeta = Join-Path -Path $hivesMeta -ChildPath ("{0}.xml" -f $HiveName)
  if (-not (Test-Path $targetHiveMeta)) {
    $m = "Config Hive with name '{0}' was not found" -f $HiveName
    $err = New-Object ConfigHiveError -ArgumentList 'HiveMetaNotFound', $m
    throw($err)
  }
  
  #$policy = New-RetryPolicy -Policy Random -Milliseconds 5000 -Retries 3
  #$hiveMeta = [HashTable] (Invoke-ScriptBlockWithRetry -Context { Import-Clixml -Path $targetHiveMeta } -RetryPolicy $policy)
  $hiveMeta = Import-Clixml -Path $targetHiveMeta
  
  # Validate existing properties 
  $metaStructure = @(
    'HiveName', 
    'OriginName', 
    'OriginData', 
    'SystemName', 
    'SystemData', 
    'UserName', 
    'UserData',
    'SessionName',
    'SessionData')
  $metaStructure | ForEach-Object {
    $prop = $_
    if ($hiveMeta.Keys -notcontains $prop) {
      $m = "Hive metadata is not in the expected format, missing property: '{0}'" -f $prop
      $err = New-Object ConfigHiveError -ArgumentList 'CorrupedHiveMetadata', $m
      throw($err)
    }
  } 
  
  if ($hiveMeta['HiveName'] -ne $HiveName) {
    $m = "Attempted to retrieve config hive metadata for '{0}' but got '{1}'" -f $HiveName, $hiveMeta['HiveName']
    $err = New-Object ConfigHiveError -ArgumentList 'CorruptedHiveMetadata', $m
    throw($err)
  }

  $instanceHiveMeta = @{
    'HiveName' = $HiveName
    'Origin'   = (New-DataStore -StoreName $hiveMeta['OriginName'] -SerializedStoreData $hiveMeta['OriginData'])
    'System'   = (New-DataStore -StoreName $hiveMeta['SystemName'] -SerializedStoreData $hiveMeta['SystemData'])
    'User'     = (New-DataStore -StoreName $hiveMeta['UserName'] -SerializedStoreData $hiveMeta['UserData'])
    'Session'  = (New-DataStore -StoreName $hiveMeta['SessionName'] -SerializedStoreData $hiveMeta['SessionData'])
  }

  $Script:ActiveConfigHives[$HiveName] = [PSCustomObject] $instanceHiveMeta
}

# Describes the levels at which stores can operate, this helps the stores to differentiate each other within the same 
# Config Hive definition as well as to take specific actions for different levels i.e. System Level files vs User level
enum CacheStoreLevel {
  Origin
  System
  User
  Session
}
