<#
.SYNOPSIS
Config Store implementation based on CliXml serialization

#>

class CliFileStore : ConfigBaseStore {
  # Static Members
  static [string]  $Name           = 'CliFileStore'
  static [Version] $Version        = [Version] '0.1.0'
  static [string]  $PolicyTypeName = 'System.xUtility.RetryPolicy'
  static           $OptionTypes    = @([TimeSpan], [ScriptBlock], [System.IO.FileInfo])
  
  # Public variables
  [string]      $CacheControlType
  [string]      $CacheId
  # NOTE: Store additional custom cache control types at this level
  [TimeSpan]    $TimedCacheControl
  [ScriptBlock] $CustomCacheControl
  
  # Internal members
  hidden [int] $ProcessId = $PID
  hidden [string] $FilePath
  hidden [PSCustomObject] $Policy
  hidden [ScriptBlock] $GetFromSource = {
    $data = @{}
    if ((Test-Path $this.FilePath)) {
      $data = Import-Clixml -Path $this.FilePath
      #$data = Invoke-ScriptBlockWithRetry -Context { Import-Clixml -Path $this.FilePath } -RetryPolicy $this.Policy
    }

    Write-Output $data
  } 
  
  # Constructor
  CliFileStore() : base() {
  }
  
  # Creates a new instance of the store
  # @Override
  [CliFileStore] NewInstance([string] $HiveName, [CacheStoreLevel] $Level) {
    $store = New-Object CliFileStore
    $store.StoreName     = [CliFileStore]::Name
    $store.StoreVersion  = [CliFileStore]::Version
    $store.HiveName      = $HiveName
    $store.StoreLevel    = $Level
    $store.IsInitialized = $true

    # Calculate the file associated with the given Hive Name
    $store.FilePath = [string]::Empty
    
    # Calculate cache key to use with this instance
    $store.CacheId = "{0}.{1}.{2}" -f [CliFileStore]::Name, $Level.ToString(), $HiveName
    #$store.Policy = New-RetryPolicy -Policy Random -Milliseconds 5000 -Retries 3
    $cacheLength = [TimeSpan] '0:0:5'
    $store.SetCustomParams($cacheLength)

    return $store
  }

  # Creates a new instance of the store using serialized data
  # @Override
  [CliFileStore] Rehydrate([string] $SerializedData) {
    $data = $SerializedData | ConvertFrom-Json
    $hydratedStore = $this.NewInstance($data.HiveName, $data.Level)
    if ($data.TimedCacheControl -ne $null) {
      $timeControl = [TimeSpan] $data.TimedCacheControl 
      $hydratedStore.SetCustomParams($timeControl)
    }
    elseif ($data.CustomCacheControl -ne $null) {
      $customControl = [ScriptBlock]::Create($data.CustomCacheControl)
      $hydratedStore.SetCustomParams($customControl)
    }
    else {
      $m = 'Unable to initialize store properly, required data is not present'
      $err = New-Object ConfigHiveError -ArgumentList 'InvalidImplementation', $m
      throw($err)
    }

    if ($data.FilePath -ne $null) {
      $file = [System.IO.FileInfo] $data.FilePath
      $hydratedStore.SetCustomParams($file)
    }

    return $hydratedStore
  }

  # Calculates the file to be used given the specified hive name and level
  [string] GetTargetFilePath([CacheStoreLevel] $Level, [string] $HiveName) {
    $basePath = [string]::Empty
    switch ($Level) {
      ([CacheStoreLevel]::Origin) {
        # NOTE: This operation requires Administrator permissions
        $basePath = Get-ProgramDataPath
      }
      ([CacheStoreLevel]::System) {
        $basePath = Get-ProgramDataPath
      }
      ([CacheStoreLevel]::User) {
        $basePath = Get-AppDataPath
        #
      }
      ([CacheStoreLevel]::Session) {
        $basePath = Get-AppDataPath
      }

      Default {
        $m = "Cli File Store: Unsupported store level: {0}" -f $Level.ToString()
        $err = New-Object ConfigHiveError -ArgumentList 'UnsupportedStoreLevel', $m
        throw($err)
      }
    }

    $targetFilePath = "{0}.xml" -f $HiveName
    $basePath = Join-Path -Path $basePath -ChildPath 'HiveData'
    $basePath = Join-Path -Path $basePath -ChildPath ([CliFileStore]::Name)
    if ($Level -eq [CacheStoreLevel]::Session) {
      $procId = $this.ProcessId
      $levelId = "{0}-{1}" -f $Level.ToString(), $procId
      $basePath = Join-Path -Path $basePath -ChildPath $levelId
    }
    else {
      $basePath = Join-Path -Path $basePath -ChildPath $Level.ToString()
    }

    if (-not (Test-Path $basePath)) {
      New-Item -ItemType Directory -Path $basePath | Write-Verbose
    }

    $targetFilePath = Join-Path -Path $basePath -ChildPath $targetFilePath

    return $targetFilePath
  }

  # Determines whether custom parameters are required or not
  # @Override
  [bool] RequiresCustomParams() {
    return $false
  }

  # Custom parameters for the store, valid data: [TimeSpan], [ScriptBlock]
  # @Override
  [void] SetCustomParams($CustomParams) {
    if ($this.IsInitialized -ne $true) {
      $m = "[Store.{0}] Attempt to use an uninitialized store" -f [CliFileStore]::Name
      $err = New-Object ConfigHiveError -ArgumentList 'UninitializedStore', $m
      throw($err)
    }

    $pType = $CustomParams.GetType()
    if ([CliFileStore]::OptionTypes -contains $pType) {
      # NOTE: Add custom supported types here
      if ($pType -eq [TimeSpan]) {
        $this.TimedCacheControl = $CustomParams
        $this.CacheControlType = $pType.ToString()
      }
      elseif ($pType -eq [ScriptBlock]) {
        $this.CustomCacheControl = $CustomParams
        $this.CacheControlType = $pType.ToString()
      }
      elseif ($pType -eq [System.IO.FileInfo]) {
        $file = [System.IO.FileInfo] $CustomParams
        if ($file.Extension -ne '.xml') {
          $m = "Cannot use a file with extension '{0}' for serialization, must use '.xml'" -f $file.Extension
          $err = New-Object ConfigHiveError -ArgumentList 'InvalidArgument', $m
          throw($err)
        }

        $this.FilePath = $file.FullName
      }
      else {
        $m = "Support for Cache Control Type '{0}' is not implemented appropriately" -f $pType
        $err = New-Object ConfigHiveError -ArgumentList 'InvalidImplementation', $m
        throw($err)
      }
    }
    else {
      $cts = [CliFileStore]::OptionTypes -join ', '
      $m = "Invalid Custom Parameter of type '{0}', valid values are {1}" -f $pType, $cts
      $err = New-Object ConfigHiveError -ArgumentList 'InvalidArgument', $m
      throw($err)
    }

    $this.ResetCache()
  }

  # Default values for the store
  # @Override
  [void] InitializeStore([HashTable] $Values) {
    if ($this.IsInitialized -ne $true) {
      $m = "[Store.{0}] Attempt to use an uninitialized store" -f [CliFileStore]::Name
      $err = New-Object ConfigHiveError -ArgumentList 'UninitializedStore', $m
      throw($err)
    }
    
    if ((Test-Path $this.FilePath)) {
      Warn -Message 'Store has been previously initialized'
    }

    if ($this.FilePath -eq [string]::Empty) {
      $this.FilePath = $this.GetTargetFilePath($this.StoreLevel, $this.HiveName)
    }

    #Invoke-ScriptBlockWithRetry -Context { $Values | Export-Clixml -Path $this.FilePath } -RetryPolicy $this.Policy
    $Values | Export-Clixml -Path $this.FilePath
    $this.ResetCache()
  }

  # Resets the cache
  [void] ResetCache() {
    $p = @{}
    switch ($this.CacheControlType) {
      ([TimeSpan].ToString()) {
        $p = @{
          Key            = $this.CacheId
          ItemDefinition = $this.GetFromSource
          Expiration     = $this.TimedCacheControl
          Force          = $true
        }
      }

      ([ScriptBlock].ToString()) {
        $p = @{
          Key            = $this.CacheId
          ItemDefinition = $this.GetFromSource
          CustomTrigger  = $this.CustomCacheControl
          Force          = $true
        }
      }

      Default {
        $m = "Support for Cache Control Type '{0}' is not implemented appropriately" -f $this.CacheControlType
        $err = New-Object ConfigHiveError -ArgumentList 'InvalidImplementation', $m
        throw($err)
      }
    }

    #Add-ExpiringCacheItem @p
  }

  # Gets a value from the store
  # @Override
  [HashTable] GetValue([string] $Key) {
    if ($this.IsInitialized -ne $true) {
      $m = "[Store.{0}] Attempt to use an uninitialized store" -f [CliFileStore]::Name
      $err = New-Object ConfigHiveError -ArgumentList 'UninitializedStore', $m
      throw($err)
    }

    #$data = [HashTable] (Get-ExpiringCacheItem -Key $this.CacheId)
    $data = [HashTable] (. $this.GetFromSource)
    if (-not ($data.Keys -contains $Key)) {
      $m = "[{0}] Store does not contain key '{1}'" -f $this.StoreName, $Key
      $err = New-Object ConfigHiveError -ArgumentList 'ValueNotFound', $m
      throw($err)
    }

    $r = @{
      'Name' = $Key
      'Value' = $data[$Key]
    }

    return $r
  }

  # Sets a value to the store
  # @Override
  [void] SetValue([string] $Key, $Value) {
    if ($this.IsInitialized -ne $true) {
      $m = "[Store.{0}] Attempt to use an uninitialized store" -f [CliFileStore]::Name
      $err = New-Object ConfigHiveError -ArgumentList 'UninitializedStore', $m
      throw($err)
    }

    if ($this.FilePath -eq [string]::Empty) {
      $this.FilePath = $this.GetTargetFilePath($this.StoreLevel, $this.HiveName)
    }

    # Read from source, read from source in case data changed
    $currentData = [HashTable](. $this.GetFromSource)
    $currentData[$Key] = $Value
    #Invoke-ScriptBlockWithRetry -Context { $currentData | Export-Clixml -Path $this.FilePath } -RetryPolicy $this.Policy
    $currentData | Export-Clixml -Path $this.FilePath
    $this.ResetCache()
  }

  # Removes a value from the store
  # @Override
  [void] RemoveValue([string] $Key) {
    if ($this.IsInitialized -ne $true) {
      $m = "[Store.{0}] Attempt to use an uninitialized store" -f [CliFileStore]::Name
      $err = New-Object ConfigHiveError -ArgumentList 'UninitializedStore', $m
      throw($err)
    }

    if ($this.FilePath -eq [string]::Empty) {
      $this.FilePath = $this.GetTargetFilePath($this.StoreLevel, $this.HiveName)
    }

    # Read from source in case data changed
    $data = [HashTable](. $this.GetFromSource)
    if ($data.Keys -ccontains $Key) {
      $data.Remove($Key)
      #Invoke-ScriptBlockWithRetry -Context { $data | Export-Clixml -Path $this.FilePath } -RetryPolicy $this.Policy
      $data | Export-Clixml -Path $this.FilePath
      $this.ResetCache()
    }
    else {
      Warn -Message ("Key: '{0}' does not exist in the store" -f $Key)
    }
  }

  # Gets a list of the keys in the store
  # @Override
  [string[]] GetKeys() {
    if ($this.IsInitialized -ne $true) {
      $m = "[Store.{0}] Attempt to use an uninitialized store" -f [CliFileStore]::Name
      $err = New-Object ConfigHiveError -ArgumentList 'UninitializedStore', $m
      throw($err)
    }

    if ($this.FilePath -eq [string]::Empty) {
      $this.FilePath = $this.GetTargetFilePath($this.StoreLevel, $this.HiveName)
    }

    #$currentData = [HashTable] (Get-ExpiringCacheItem -Key $this.CacheId)
    $currentData = [HashTable] (. $this.GetFromSource)
    return $currentData.Keys
  }

  # Sets a custom retry policy for writting into the file
  [void] SetCustomRetryPolicy([PSCustomObject] $proposedPolicy) {
    if ($this.IsInitialized -ne $true) {
      $m = "[Store.{0}] Attempt to use an uninitialized store" -f [CliFileStore]::Name
      $err = New-Object ConfigHiveError -ArgumentList 'UninitializedStore', $m
      throw($err)
    }

    if ($proposedPolicy.PSTypeNames[0] -ne [CliFileStore]::PolicyTypeName) {
      $m = "[Store.{0}] Invalid Retry Policy object: {1}", [CliFileStore]::Name, $proposedPolicy.PSTypeNames[0]
      $err = New-Object ConfigHiveError -ArgumentList 'InvalidRetryPolicyObject', $m
      throw($err)
    }

    $this.Policy = $proposedPolicy
  }

  # Serialize initialization data
  # @Override
  [string] SerializeInstanceData() {
    if ($this.IsInitialized -ne $true) {
      $m = "[Store.{0}] Attempt to use an uninitialized store" -f [CliFileStore]::Name
      $err = New-Object ConfigHiveError -ArgumentList 'UninitializedStore', $m
      throw($err)
    }

    $serialData = @{}
    $serialData['HiveName'] = $this.HiveName
    $serialData['Level'] = ([string] $this.StoreLevel)

    if ($this.FilePath -ne [string]::Empty) {
      $serialData['FilePath'] = ([System.IO.FileInfo] $this.FilePath).FullName
    }

    if ($this.CacheControlType -eq [TimeSpan].ToString()) {
      $controlStr = $this.TimedCacheControl.ToString()
      $serialData['TimedCacheControl'] = $controlStr
    }
    elseif ($this.CacheControlType -eq [ScriptBlock].ToString()) {
      $controlStr = $this.CustomCacheControl.ToString()
      $serialData['CustomCacheControl'] = $controlStr
    }
    else {
      $m = "Serialization for Cache Control Type '{0}' is not supported" -f $this.CacheControlType
      $err = New-Object ConfigHiveError -ArgumentList 'InvalidImplementation', $m
      throw($err)
    }

    return ($serialData | ConvertTo-Json -Compress )
  }
}

$Script:AvailableStores += 'CliFileStore'
