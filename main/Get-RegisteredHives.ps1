<#
.SYNOPSIS
Lists registered configuration hives

.DESCRIPTION
Reads previous registered hives metadata and return the names of them

.NOTES
Certain operations might require admin privileges. In particular System, Origin level stores on CliFileStore are known
for this requirement

#>

function Get-RegisteredHives {
  [CmdletBinding()]
  param(
    # Name of the Registered Hive
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $Name = ''
  )

  $ErrorActionPreference = 'Stop'
  $hivesMeta = Get-HiveMetaPath
  $registeredHives = @()
  Get-ChildItem -Path $hivesMeta -Filter '*.xml' | ForEach-Object {
    $registeredHives += $_.BaseName
  }

  if ('' -ne $Name) {
    $registeredHives | Where-Object { $_ -eq $Name } | Write-Output
  } else {
    Write-Output $registeredHives
  }
}
