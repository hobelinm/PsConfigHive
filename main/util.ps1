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
  
  if ($NoNewLine) {
    Write-Host "] $Message" -NoNewline
  }
  else {
    Write-Host "] $Message"
  }
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
function Get-AppDataPath {
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
    $baseName = GetConfig('Module.BaseName')
    $location = Join-Path -Path $location -ChildPath $baseName
    if (-not (Test-Path $location)) {
      New-Item -ItemType Directory -Path $location | Write-Verbose
    }
  }
  
  Write-Output $location
}

# Gets the location of the implemented stores
function Get-StorePath {
  [CmdletBinding()]
  param()

  $ErrorActionPreference = 'Stop'
  $appData = Get-AppDataPath
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

  if ($PSVersionTable.OS -eq $null -or $PSVersionTable.OS.Contains('Windows')) {
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

function GetConfig {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string] $Key
  )

  $ErrorActionPreference = 'Stop'
  # TODO:
  # Check first on non-overridable defaults
  $constConfig = [HashTable] $Script:DefaultConfig
  if ($constConfig.Keys -contains $Key) {
    Write-Output $constConfig[$Key]
  }
  elseif ($Script:ModuleLoadComplete -eq $true) {
    # Use service if we have user configurable options if available
    $err = New-Object ConfigHiveError -ArgumentList 'NotImplementedException', 'This option is not implemented yet'
    throw($err.ToString())
  }
  else {
    # otherwise use default overridable options
    $baseConfig = [HashTable] $Script:BaseConfigOverridable
    Write-Output $baseConfig[$Key]
  }
}
