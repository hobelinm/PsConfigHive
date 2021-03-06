<####################################
# Default non-overridable settings
######################################>
$Script:DefaultConfig = @{}

# StorePath
$Script:DefaultConfig['Module.StorePath.BaseName'] = 'Stores'
# Module
$Script:DefaultConfig['Module.BaseName'] = 'ConfigHive'
$Script:DefaultConfig['Module.Version'] = [Version] (. {
  $moduleTemp = Get-TempPath
  $manifest = Join-Path -Path $Script:ModuleHome -ChildPath 'ConfigHive.psd1'
  $tmpManifest = Join-Path -Path $moduleTemp -ChildPath 'ConfigHive.ps1'
  Copy-Item -Path $manifest -Destination $tmpManifest -Force
  $manifestData = . $tmpManifest
  Write-Output $manifestData.ModuleVersion
})

$Script:DefaultConfig['Module.WorkPath'] = GetAppDataPath
$Script:DefaultConfig['Module.StoresPath'] = . {
  $appData = GetAppDataPath
  $storesPath = Join-Path -Path $appData -ChildPath 'stores'
  if (-not (Test-Path $storesPath)) {
    New-Item -ItemType Directory -Path $storesPath | Write-Verbose
  }

  Write-Output $storesPath
}

$Script:DefaultConfig['Module.Dependencies'] = @('xUtility')
$Script:DefaultConfig['Module.HiveMetaDirectory'] = 'HiveMeta'
$Script:DefaultConfig['Module.PackageVersionUrl'] = 'https://raw.githubusercontent.com/hobelinm/PsConfigHive/master/package.json'

<####################################
# Default overridable settings
######################################>
$Script:BaseConfigOverridable = @{}
$Script:BaseConfigOverridable['Module.AccentColor'] = 'Cyan'
$Script:BaseConfigOverridable['Module.UpdateFile'] = . {
  $temp = Get-TempPath
  $updateFile = Join-Path -Path $temp -ChildPath 'UpdateCheck.xml'
  Write-Output $updateFile
}

$Script:BaseConfigOverridable['Module.UpdateCheckSpan'] = [TimeSpan] '30.00:00:00'
