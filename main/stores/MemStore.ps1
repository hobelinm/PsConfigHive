<#
.SYNOPSIS
In memory implementation of a config store

.NOTES
For examples see New-DataStore cmdlet
SetCustomParams is not implemented in this store because it is not required

#>

class MemStore : ConfigBaseStore {
  # Static Members
  static [string]  $Name    = 'MemStore'
  static [Version] $Version = [Version] '0.1.0'

  # Internal Members
  hidden [HashTable] $StoreData

  # Constructor
  MemStore() : base() {
  }

  # Creates a new instance of the store
  # @Override
  [MemStore] NewInstance([string] $HiveName, [CacheStoreLevel] $Level) {
    $store = New-Object MemStore
    $store.StoreName     = [MemStore]::Name
    $store.StoreVersion  = [MemStore]::Version
    $store.HiveName      = $HiveName
    $store.StoreLevel    = $Level
    $store.StoreData     = @{}
    $store.IsInitialized = $true
    return $store
  }
  
  # Creates a new instance of the store using serialized data
  # @Override
  [MemStore] Rehydrate([string] $SerializedData) {
    $data = $SerializedData | ConvertFrom-Json
    return $this.NewInstance($data.HiveName, $data.Level)
  }

  # Initializes the store with a given set of values
  # @Override
  [void] InitializeStore([HashTable] $Values) {
    if ($this.IsInitialized -ne $true) {
      $m = "[Store.{0}] Attempt to use an uninitialized store" -f [MemStore]::Name
      $err = New-Object ConfigHiveError -ArgumentList 'UninitializedStore', $m
      throw($err)
    }

    if ($this.StoreData.Keys.Count -gt 0) {
      Warn -Message 'Store has been previously initialized'
    }

    $this.StoreData = $Values
  }

  # Determines whether custom parameters are required or not
  # @Override
  [bool] RequiresCustomParams() {
    return $false
  }

  # Gets a stored value
  # @Override
  [HashTable] GetValue([string] $Key) {
    if ($this.IsInitialized -ne $true) {
      $m = "[Store.{0}] Attempt to use an uninitialized store" -f [MemStore]::Name
      $err = New-Object ConfigHiveError -ArgumentList 'UninitializedStore', $m
      throw($err)
    }

    if (-not ($this.StoreData.Keys -contains $Key)) {
      $m = "[{0}] Store does not contain key '{1}'" -f $this.StoreName, $Key
      $err = New-Object ConfigHiveError -ArgumentList 'ValueNotFound', $m
      throw($err)
    }

    $r = @{
      'Name' = $Key
      'Value' = $this.StoreData[$Key]
    }
    
    return $r
  }

  # Sets/Overrides a value from the store
  # @Override
  [void] SetValue([string] $Key, $Value) {
    if ($this.IsInitialized -ne $true) {
      $m = "[Store.{0}] Attempt to use an uninitialized store" -f [MemStore]::Name
      $err = New-Object ConfigHiveError -ArgumentList 'UninitializedStore', $m
      throw($err)
    }

    $this.StoreData[$Key] = $Value
  }

  # Removes a value from the store
  # @Override
  [void] RemoveValue([string] $Key) {
    if ($this.IsInitialized -ne $true) {
      $m = "[Store.{0}] Attempt to use an uninitialized store" -f [MemStore]::Name
      $err = New-Object ConfigHiveError -ArgumentList 'UninitializedStore', $m
      throw($err)
    }

    if ($this.StoreData.Keys -ccontains $Key) {
      $this.StoreData.Remove($Key)
    }
    else {
      Warn -Message ("Key: '{0}' does not exist in the store" -f $Key)
    }
  }

  # Gets existing keys in the store
  # @Override
  [string[]] GetKeys() {
    return $this.StoreData.Keys
  }

  # Serialize initialization data
  # @Override
  [string] SerializeInstanceData() {
    if ($this.IsInitialized -ne $true) {
      $m = "[Store.{0}] Attempt to use an uninitialized store" -f [MemStore]::Name
      $err = New-Object ConfigHiveError -ArgumentList 'UninitializedStore', $m
      throw($err)
    }

    $serialData = @{}
    $serialData['HiveName'] = $this.HiveName
    $serialData['Level'] = ([string] $this.StoreLevel)
    return ($serialData | ConvertTo-Json -Compress )
  }
}

$Script:AvailableStores += 'MemStore'
