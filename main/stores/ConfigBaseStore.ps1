<#
.SYNOPSIS
Defines the required implementation of a config store

.DESCRIPTION
Abstract class used to outline the requirements of all store implementations as well as to validate 
store implementations

#>

class ConfigBaseStore {
  # Parameterless Constructor
  ConfigBaseStore () {
    $type = $this.GetType()
    if ($type -eq [ConfigBaseStore]) {
      $err = New-Object ConfigHiveError -ArgumentList 'InvalidInstance', "Class 'ConfigBaseStore' must be inherited"
      throw($err.ToString())
    }
  }

  [string] GetName() {
    $err = New-Object ConfigHiveError -ArgumentList 'NotImplementedMember', "Must override 'GetName' method"
    throw($err.ToString())
  }

  [Version] GetVersion() {
    $err = New-Object ConfigHiveError -ArgumentList 'NotImplementedMember', "Must override 'GetVersion' method"
    throw($err.ToString())
  }
}
