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

<####################################
# Default overridable settings
######################################>
$Script:BaseConfigOverridable = @{}
$Script:BaseConfigOverridable['Module.AccentColor'] = 'Cyan'
