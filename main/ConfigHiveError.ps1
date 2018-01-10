<#
.SYNOPSIS
Definition for error types and custom erroring
#>

enum ErrorCategory {
  ConfigHiveLoadFailure
  ConfigHiveNotFound
  CorruptedHiveMetadata
  DuplicateHiveName
  HiveMetaNotFound
  KeyNotFound
  NotImplementedException
  NotImplementedMember
  InvalidArgument
  InvalidImplementation
  InvalidInstance
  InvalidRetryPolicyObject
  StoreNotFound
  UninitializedStore
  UnsupportedStoreLevel
  ValueNotFound
}

class ConfigHiveError : System.Exception {
  [ErrorCategory] $Category
  [string] $Message
  [string] $Caller

  ConfigHiveError(
    [ErrorCategory] $Category,
    [string] $Message) : base((
      "[ConfigHive.{0}.{1}] {2}" -f (Get-PSCallStack)[1].FunctionName, $Category, $Message
    )) {
    
    $this.Caller = (Get-PSCallStack)[1].FunctionName
    $this.Category = $Category
    $this.Message = $Message

    # TO DO: Write telemetry
  }

  [string] ToString() {
    $m = ''
    if ($this.Caller -ne '<ScriptBlock>') {
      $m = "[ConfigHive.{0}.{1}] {2}" -f $this.Caller, $this.Category, $this.Message
    }
    else {
      $m = "[ConfigHive.Error.{0}] {1}" -f $this.Category, $this.Message
    }

    return $m
  }
}
