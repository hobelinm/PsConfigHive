<#
.SYNOPSIS
    Gets the Hive Name for the current scope

.DESCRIPTION
    Gets the Hive Name for the current scope, this means that caller stack gets inspected in order to get the
    appropriate scope. This cmdlet uses Get-PSCallStack to understand the call hierarchy and determine the caller
    scope to use.
    - When the caller is on the console or console defined (i.e. console defined functions/script blocks) the script
    returns 'ConsoleScope' by default
    - When the caller is a defined script file .ps1 the file name will be returned (i.e. myScript.ps1)
    - When the caller is a module the name of the module will be returned

.EXAMPLE
PS> Get-CurrentHiveName
Returns the current hive name: 'ConsoleScope' when called from the command line
Returns the current hive name: 'ScriptName.ps1' when called from within a script file
Returns the current hive name: 'ModuleName' when called from within a module

.EXAMPLE
PS> function func { param(); Get-CurrentHiveName }
PS> func
Returns the current hive name: 'ConsoleScope' when called from the command line
Returns the current hive name: 'ScriptName.ps1' when called from within a script file
Returns the current hive name: 'ModuleName' when called from within a module

.EXAMPLE
PS> $block = { Get-CurrentHiveName }
PS> . $block
Returns the current hive name: 'ConsoleScope' when called from the command line
Returns the current hive name: 'ScriptName.ps1' when called from within a script file
Returns the current hive name: 'ModuleName' when called from within a module

.LINK
https://github.com/hobelinm/PsConfigHive

#>

function Get-CurrentHiveName {
    [CmdletBinding()]
    param()

    $ErrorActionPreference = 'Stop'
    $scripBlockCmd = '<ScriptBlock>'
    $noFileLabel = '<No file>'
    $callStacks = Get-PSCallStack
    $loadedModules = Get-Module
    $foundCommand = $false
    Get-PSCallStack | Out-String | Write-Verbose

    1..$callStacks.Count | Where-Object { -not $foundCommand } | ForEach-Object {
        $callStack = $callStacks[$_]
        $commandName = [string] $callStack.Command
        if ($commandName -eq $scripBlockCmd -and $callStack.Location -eq $noFileLabel) {
            $foundCommand = $true
            Write-Output 'ConsoleScope'
        }
        elseif ($commandName -eq $scripBlockCmd) {
            # Find any module that contains the path of the script that contains the execution
            $scriptBlockFile = $callStack.InvocationInfo.ScriptName
            $sourceModule = $null
            $sourceModule = $loadedModules | Where-Object { $_.FileList -contains $scriptBlockFile }
            if ($sourceModule -eq $null) {
                # Some modules do not disclose the FileList so we need to do something more creative using
                # the module's path
                $sourceModule = $loadedModules | Where-Object {
                    $modulePath = ([System.IO.FileInfo] $_.Path).Directory.FullName
                    if ($callStack.ScriptName.StartsWith($modulePath)) {
                        return $true
                    }
                    else {
                        return $false
                    }
                }
            }

            if ($sourceModule -ne $null) {
                $foundCommand = $true
                Write-Output $sourceModule.Name
            }
            else {
                # Get the script name
                $foundCommand = $true
                $scriptName = [System.IO.FileInfo] $callStack.ScriptName
                Write-Output $scriptName.Name
            }
        }
        elseif ($commandName.EndsWith('.ps1') -or $commandName.EndsWith('.psm1')) {
            $foundCommand = $true
            Write-Output $commandName
        }
        else {
            # Here we've got two cases:
            # a function name exposed by a module/script
            # a function name not exposed by it
            $loadedModules | Where-Object { -not $foundCommand} | ForEach-Object {
                $moduleDefinition = $_
                if ($moduleDefinition.ExportedAliases.Keys.Contains($commandName)) {
                    $foundCommand = $true
                    Write-Output $moduleDefinition.Name
                }
                elseif ($moduleDefinition.ExportedCmdlets.Keys.Contains($commandName)) {
                    $foundCommand = $true
                    Write-Output $moduleDefinition.Name
                }
                elseif ($moduleDefinition.ExportedCommands.Keys.Contains($commandName)) {
                    $foundCommand = $true
                    Write-Output $moduleDefinition.Name
                }
                elseif ($moduleDefinition.ExportedDscResources.Contains($commandName)) {
                    $foundCommand = $true
                    Write-Output $moduleDefinition.Name
                }
                elseif ($moduleDefinition.ExportedFunctions.Keys.Contains($commandName)) {
                    $foundCommand = $true
                    Write-Output $moduleDefinition.Name
                }
                elseif ($moduleDefinition.ExportedWorkflows.Keys.Contains($commandName)) {
                    $foundCommand = $true
                    Write-Output $moduleDefinition.Name
                }
            }

            # Function name was not exposed
            if (-not $foundCommand) {
                $functionFile = $callStack.InvocationInfo.ScriptName
                $sourceModule = $loadedModules | Where-Object { $_.FileList -contains $functionFile }
                if ($sourceModule -ne $null) {
                    Write-Output $sourceModule.Name
                    $foundCommand = $true
                }
            }
        }
    }
}
