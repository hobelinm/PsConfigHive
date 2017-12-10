<#
.SYNOPSIS
Definition for error types and custom erroring
#>

enum ErrorCategory {
  NotImplementedException
  NotImplementedMember
  InvalidInstance
}

class ConfigHiveError {
  [ErrorCategory] $Category
  [string] $Message

  ConfigHiveError(
    [ErrorCategory] $Category,
    [string] $Message) {

    $this.Category = $Category
    $this.Message = $Message
  }

  [string] ToString() {
    return ("[ConfigHive.{0}] {1}" -f $this.Category, $this.Message)
  }
}
