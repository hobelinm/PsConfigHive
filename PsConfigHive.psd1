@{

# Script module or binary module file associated with this manifest.
# RootModule = 'PsConfigHive.psm1'

# Version number of this module.
ModuleVersion = '0.1.2'

# ID used to uniquely identify this module
GUID = 'afd64af8-636e-4de9-85a6-15f8af0c877a'

# Author of this module
Author = 'Hugo Belin'

# Company or vendor of this module
# CompanyName = ''

# Copyright statement for this module
Copyright = '(c) Hugo Belin. All rights reserved.'

# Description of the functionality provided by this module
Description = 'PowerShell Configuration Manager'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @('PsConfigHive.psm1')

# Functions to export from this module
FunctionsToExport = @(
    'Get-CurrentHiveName'
)

# Cmdlets to export from this module
# CmdletsToExport = '*'

# Variables to export from this module
# VariablesToExport = '*'

# Aliases to export from this module
# AliasesToExport = '*'

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
FileList = @(
    '.\LICENSE',
    '.\PsConfigHive.psd1',
    '.\PsConfigHive.psm1',
    '.\README.md',
    '.\Main\Get-CurrentHiveName.ps1'
)

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('Utility', 'Console', 'Configuration')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/hobelinm/PsConfigHive/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/hobelinm/PsConfigHive'

        # A URL to an icon representing this module.
        IconUri = 'https://github.com/hobelinm/PsxUtility'

        # ReleaseNotes of this module
        ReleaseNotes = 'Initial Alpha Version'

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
HelpInfoURI = 'https://github.com/hobelinm/PsConfigHive'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

