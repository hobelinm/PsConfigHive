<#
.SYNOPSIS
Gets the path of the custom stores

.DESCRIPTION
Retrieves the path that the module uses for loading custom stores. This is useful for developing and adding new stores

#>

function Get-CustomStorePath {
  [CmdletBinding()]
  param()

  $ErrorActionPreference = 'Stop'

  Write-Output (Get-StorePath)
}
