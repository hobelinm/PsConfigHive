<#
.SYNOPSIS
Tests for ConfigHive module

.EXAMPLE
'MemStoreRehydrateTest' | . ./test.ps1

.EXAMPLE
'RegisterTestHive' | . ./test.ps1

.EXAMPLE
'GetSetMultiLevel' | . ./test.ps1

.EXAMPLE
'GetSetValue' | . ./test.ps1

.EXAMPLE
$tests = @('MemStoreRehydrateTest', 'CliFileStoreRehydrateTest', 'RegisterTestHive', 'GetSetValue', 'GetSetMultiLevel')
$tests | . ./test.ps1

#>
[CmdletBinding()]
param(
  [Parameter(Mandatory, ValueFromPipeline)]
  [ValidateSet(
    'MemStoreRehydrateTest', 
    'CliFileStoreRehydrateTest', 
    'RegisterTestHive', 
    'GetSetValue',
    'GetSetMultiLevel'
  )]
  [string] $TestCase
)

begin {
  $ErrorActionPreference = 'Stop'
  $modName = Join-Path -Path $PSScriptRoot -ChildPath './ConfigHive.psd1'
  Import-Module $modName
  $testReport = @{}
  
  # Basic printing function
  function TestPrint {
    [CmdletBinding()]
    param(
      [Parameter(Mandatory)]
      [string] $Message,
  
      [Parameter()]
      [System.ConsoleColor] $Accent = 'Cyan',
  
      [Parameter()]
      [System.ConsoleColor] $MessageColor,
  
      [Parameter()]
      [switch] $NoNewLine = $false
    )
    Write-Host '[' -NoNewline
    Write-Host 'Test' -ForegroundColor $Accent -NoNewline
    Write-Host '.' -NoNewline
    Write-Host 'ConfigHive' -ForegroundColor $Accent -NoNewline
    Write-Host '.' -NoNewline
    Write-Host $TestCase -ForegroundColor $Accent -NoNewline
    
    $p = @{
      'Object'          = "] $Message"
      'NoNewLine'       = $NoNewLine
    }
  
    if ($MessageColor -ne $null) {
      Write-Host '] ' -NoNewline
      $p['Object'] = $Message
      $p['ForegroundColor'] = $MessageColor
    }
  
    Write-Host @p
  }
  
  TestPrint -Message 'Starting Test'
}

process {
  $testReport[$TestCase] = 'FAIL'
  # Test creation and rehydration of a MemStore
  if ($TestCase -eq 'MemStoreRehydrateTest') {
    $memStore = New-DataStore -HiveName 'Test' -StoreName 'MemStore' -StoreLevel 'User'
    $m = "Initial Store - Hive Name: '{0}' - Level: '{1}'" -f $memStore.HiveName, $memStore.StoreLevel
    TestPrint -Message $m
    $testStore = New-DataStore -StoreName 'MemStore' -SerializedStoreData $memStore.SerializeInstanceData()
    $m = "Hydrated Store - Hive Name: '{0}' - Level: '{1}'" -f $testStore.HiveName, $testStore.StoreLevel
    TestPrint -Message $m
    if ($memStore.StoreName -eq $testStore.StoreName    -and
    $memStore.StoreVersion  -eq $testStore.StoreVersion -and 
    $memStore.HiveName      -eq $testStore.HiveName     -and 
    $memStore.StoreLevel    -eq $testStore.StoreLevel   -and 
    $memStore.IsInitialized -eq $testStore.IsInitialized) {
      TestPrint -Message ("Stores are equal. Test '{0}' PASSED" -f $TestCase) -Accent 'Green'
      $testReport[$TestCase] = 'PASS'
    }
    else {
      TestPrint -Message ("Stores are different. Test '{0}' FAILED" -f $TestCase) -Accent 'Red'
      Write-Output $memStore
      Write-Output $testStore
    }
  }
  elseif ($TestCase -eq 'CliFileStoreRehydrateTest') {
    $cliStore = New-DataStore -HiveName 'Test' -StoreName 'CliFileStore' -StoreLevel 'User' -Options ([TimeSpan] '0:0:5')
    $m = "Initial Store - Hive Name: '{0}' - Level: '{1}' uses TimeSpan" -f $cliStore.HiveName, $cliStore.StoreLevel
    TestPrint -Message $m
    $testStore = New-DataStore -StoreName 'CliFileStore' -SerializedStoreData $cliStore.SerializeInstanceData()
    $m = "Hydrated Store - Hive Name: '{0}' - Level: '{1}' uses TimeSpan" -f $testStore.HiveName, $testStore.StoreLevel
    TestPrint -Message $m
    if ($cliStore.StoreName    -eq $testStore.StoreName -and
    $cliStore.StoreVersion     -eq $testStore.StoreVersion -and
    $cliStore.HiveName         -eq $testStore.HiveName -and 
    $cliStore.StoreLevel       -eq $testStore.StoreLevel -and
    $cliStore.IsInitialized    -eq $testStore.IsInitialized -and
    $cliStore.CacheControlType -eq $testStore.CacheControlType -and
    $cliStore.CacheId          -eq $testStore.CacheId) {
      TestPrint -Message ("Stores are equal. Test '{0}' PASSED" -f $TestCase) -Accent 'Green'
      $testReport[$TestCase] = 'PASS'
    }
    else {
      TestPrint -Message ("Stores are different. Test '{0}' FAILED" -f $TestCase) -Accent 'Red'
      Write-Output $cliStore
      Write-Output $testStore
    }
  }
  elseif ($TestCase -eq 'RegisterTestHive') {
    TestPrint -Message 'Running RegisterTestHive test'
    try {
      TestPrint -Message 'Registering Test config hive'
      Register-ConfigHive -HiveName 'Test'
      TestPrint -Message 'Attempting to register Test config hive again'
      Register-ConfigHive -HiveName 'Test'
    }
    catch {
      $e = $_
      $startEMsg = '[ConfigHive.Register-ConfigHive.DuplicateHiveName]'
      if ($e.CategoryInfo.Reason -eq 'ConfigHiveError' -and $e.ToString().StartsWith($startEMsg)) {
        TestPrint -Message 'Config Hive named "Test" already exists, retrying using -Force'
        Register-ConfigHive -HiveName 'Test' -Force
      }
      else {
        throw $e
      }
    }
    $registeredStores = @(Get-RegisteredHives)
    if ($registeredStores -contains 'Test') {
      TestPrint -Message "Registered hive with name 'Test' successfully" -Accent 'Green'
      TestPrint -Message 'Unregistering Test config hive...'
      Unregister-ConfigHive -HiveName 'Test'
      $testReport[$TestCase] = 'PASS'
    }
    else {
      $m = ("FAIL: Attempted to register hive named 'Test', but only found: {0}" -f ($registeredStores -join ', '))
      TestPrint -Message $m -Accent 'Red'
    }
  }
  elseif ($TestCase -eq 'GetSetValue') {
    TestPrint -Message "Registering 'Test' config hive"
    Register-ConfigHive -HiveName 'Test' -Force
    $now = Get-Date
    TestPrint -Message ("Setting a Test value with the current date: {0}" -f $now)
    Set-ConfigValue -Key 'Test' -Value $now -HiveName 'Test'
    TestPrint -Message "Retrieving stored value under 'Test'"
    $val = Get-ConfigValue -Key 'Test' -HiveName 'Test'
    if ($now -eq $val) {
      TestPrint -Message 'Successfully set and get value for default hive registration' -Accent Green
      $testReport[$TestCase] = 'PASS'
    }
    else {
      TestPrint -Message 'Unable to set and get value from default store' -Accent 'Red'
    }

    Unregister-ConfigHive -HiveName 'Test'
  }
  elseif ($TestCase -eq 'GetSetMultiLevel') {
    TestPrint -Message "Registering 'Test' config hive"
    Register-ConfigHive -HiveName 'Test' -Force
    TestPrint -Message 'Adding values to multiple levels...'
    Set-ConfigValue -Key 'Description' -Value 'Console User Level Setting' -HiveName 'Test' -Level 'User'
    Set-ConfigValue -Key 'Test' -Value 'TestOrigin' -HiveName 'Test' -Level 'Origin'
    Set-ConfigValue -Key 'Test' -Value 'TestSystem' -HiveName 'Test' -Level 'System'
    TestPrint -Message 'Validating overriding mechanism...'
    $val = Get-ConfigValue -Key 'Test' -HiveName 'Test'
    if ($val -ne 'TestSystem') {
      TestPrint -Message 'Overriding mechanism not working properly' -Accent Red
    }
    else {
      TestPrint -Message 'Validating overriding mechanism...DONE'
      TestPrint -Message 'Validating original data'
      $val = Get-ConfigValue -Key 'Test' -HiveName 'Test' -Level 'Origin'
      if ($val -ne 'TestOrigin') {
        TestPrint -Message 'Origin data was not preserved after overriding at higher level' -Accent Red
      }
      else {
        Set-ConfigValue -Key 'Origin' -Value 'Origin' -HiveName 'Test' -Level 'Origin'
        Set-ConfigValue -Key 'System' -Value 'System' -HiveName 'Test' -Level 'System'
        Set-ConfigValue -Key 'User' -Value 'User' -HiveName 'Test' -Level 'User'
        Set-ConfigValue -Key 'Session' -Value 'Session' -HiveName 'Test' -Level 'Session'
        $reference = @{
          'Description' = 'Console User Level Setting'
          'Test'        = 'TestSystem'
          'Origin'      = 'Origin'
          'System'      = 'System'
          'User'        = 'User'
          'Session'     = 'Session'
        }

        TestPrint -Message 'Validating stored values...'
        $hiveData = Get-ConfigHive -HiveName 'Test'
        $processData = $true
        $reference.Keys | Where-Object { $processData } | ForEach-Object {
          $key = $_
          if ($hiveData[$key] -ne $reference[$key]) {
            TestPrint -Message ("Stored data does not match given data for key: {0}" -f $key) -Accent Red
            $result = @{
              'Key'       = $key
              'Reference' = $reference[$key]
              'Stored'    = $hiveData[$key]
            }

            Write-Output $result

            TestPrint -Message 'Hive Data:'
            Get-ConfigHive -HiveName 'Test'
            $processData = $false
          }
        }

        if ($processData -eq $true) {
          TestPrint -Message 'Validating stored values...DONE' -Accent Green
          $testReport[$TestCase] = 'PASS'
        }
      }
    }

    TestPrint -Message "Cleanup 'Test' config hive"
    Unregister-ConfigHive -HiveName 'Test'
  }
  # Add more tests here
}

end {
  $colorSet = @{
    'PASS' = (New-ConsoleColorSet -ForegroundColor Green)
    'FAIL' = (New-ConsoleColorSet -ForegroundColor Red)
  }

  $TestCase = 'Report'
  TestPrint -Message 'Test Report:'
  $testReport | Out-String | Out-ColorFormat -WordColorSet $colorSet
}
