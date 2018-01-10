<#
.SYNOPSIS
Removes a configuration hive registration metadata

.DESCRIPTION
Removes a configuration hive registration metadata

.EXAMPLE
Unregister-ConfigHive -HiveName 'Test'

Unregister configuration hive named 'Test'

#>

function Unregister-ConfigHive {
  [CmdletBinding()]
  param(
    # Name of the configuration hive to unregister
    [Parameter(Mandatory)]
    [Alias('Name')]
    [ValidateNotNullOrEmpty()]
    [string] $HiveName
  )

  $ErrorActionPreference = 'Stop'
  $existinRegistrations = @(Get-RegisteredHives)
  if (($existinRegistrations -notcontains $HiveName)) {
    Print -Message ("Config Hive with name '{0}' was not found among registered Config Hives" -f $HiveName)
    return
  }

  $hivesMeta = Get-HiveMetaPath
  $targetHive = Join-Path -Path $hivesMeta -ChildPath ("{0}.xml" -f $HiveName)
  $policy = New-RetryPolicy -Policy Random -Milliseconds 5000 -Retries 3
  Invoke-ScriptBlockWithRetry -Context { Remove-Item -Path $targetHive } -RetryPolicy $policy
}
