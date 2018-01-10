<#
.SYNOPSIS
Defines the required implementation of a config store

.DESCRIPTION
Abstract class used to outline the requirements of all store implementations as well as to validate 
store implementations

#>

class ConfigBaseStore {
  # Public Variables
  [string]          $StoreName
  [Version]         $StoreVersion
  [string]          $HiveName
  [CacheStoreLevel] $StoreLevel
  [bool]            $IsInitialized

  # Default constructor
  ConfigBaseStore() {
    $type = $this.GetType()
    if ($type -eq [ConfigBaseStore]) {
      $err = New-Object ConfigHiveError -ArgumentList 'InvalidInstance', "Class 'ConfigBaseStore' must be inherited"
      throw($err)
    }

    $this.IsInitialized = $false
  }

  # Get the calculated index for caching cmdlets
  [string] GetCacheIndexName() {
    return ("{0}.{1}" -f $this.StoreName, $this.HiveName)
  }

  # Creates a new instance of the store
  [ConfigBaseStore] NewInstance([string] $HiveName, [CacheStoreLevel] $Level) {
    $m = "Method 'NewInstance' is not implemented for store '{0}'" -f $this.StoreName
    $err = New-Object ConfigHiveError -ArgumentList 'NotImplementedMember', $m
    throw($err)
  }

  # Creates a store using serialized data, this is used when recreating stores after they've been registered
  [ConfigBaseStore] Rehydrate([string] $SerializedData) {
    $m = "Method 'Rehydrate' is not implemented for store '{0}'" -f $this.StoreName
    $err = New-Object ConfigHiveError -ArgumentList 'NotImplementedMember', $m
    throw($err)
  }

  # Allows for custom store initializations that require additional user info
  [void] SetCustomParams($CustomParams) {
    $m = "Method 'SetCustomParams' is not implemented for store '{0}'" -f $this.StoreName
    $err = New-Object ConfigHiveError -ArgumentList 'NotImplementedMember', $m
    throw($err)
  }

  # Determines whether custom parameters are required or not
  [bool] RequiresCustomParams() {
    $m = "Method 'RequiresCustomParams' is not implemented for store '{0}'" -f $this.StoreName
    $err = New-Object ConfigHiveError -ArgumentList 'NotImplementedMember', $m
    throw($err)
  }

  # Initializes a store to a default set of values
  [void] InitializeStore([HashTable] $Values) {
    $m = "Method 'InitializeStore' is not implemented for store '{0}'" -f $this.StoreName
    $err = New-Object ConfigHiveError -ArgumentList 'NotImplementedMember', $m
    throw($err)
  }

  # Gets a value from the store
  [HashTable] GetValue([string] $Key) {
    $m = "Method 'GetValue' is not implemented for store '{0}'" -f $this.StoreName
    $err = New-Object ConfigHiveError -ArgumentList 'NotImplementedMember', $m
    throw($err)
  }

  # Sets/overrides a value in the store
  [void] SetValue([string] $Key, $Value) {
    $m = "Method 'SetValue' is not implemented for store '{0}'" -f $this.StoreName
    $err = New-Object ConfigHiveError -ArgumentList 'NotImplementedMember', $m
    throw($err)
  }

  # Removes an existing value from the store
  [void] RemoveValue([string] $Key) {
    $m = "Method 'RemoveValue' is not implemented for store '{0}'" -f $this.StoreName
    $err = New-Object ConfigHiveError -ArgumentList 'NotImplementedMember', $m
    throw($err)
  }

  # Gets a list of the existing keys on the store
  [string[]] GetKeys() {
    $m = "Method 'GetKeys' is not implemented for store '{0}'" -f $this.StoreName
    $err = New-Object ConfigHiveError -ArgumentList 'NotImplementedMember', $m
    throw($err)
  }

  # Provides a way to rehydrate a store
  [string] SerializeInstanceData() {
    $m = "Method 'SerializeInstanceData' is not implemented for store '{0}'" -f $this.StoreName
    $err = New-Object ConfigHiveError -ArgumentList 'NotImplementedMember', $m
    throw($err)
  }
}
