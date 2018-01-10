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

$Script:DefaultConfig['Module.WorkPath'] = Get-AppDataPath
$Script:DefaultConfig['Module.StoresPath'] = . {
  $appData = Get-AppDataPath
  $storesPath = Join-Path -Path $appData -ChildPath 'stores'
  if (-not (Test-Path $storesPath)) {
    New-Item -ItemType Directory -Path $storesPath | Write-Verbose
  }

  Write-Output $storesPath
}

$Script:DefaultConfig['Module.Dependencies'] = @('xUtility')
$Script:DefaultConfig['Module.HiveMetaDirectory'] = 'HiveMeta'

<####################################
# Default overridable settings
######################################>
$Script:BaseConfigOverridable = @{}
$Script:BaseConfigOverridable['Module.AccentColor'] = 'Cyan'
