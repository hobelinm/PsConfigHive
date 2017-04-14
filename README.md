PowerShell Config Hive
============
A hive for your config needs

Current Version: `0.1.2`

```
Major.Minor.Build
  |     |     |_____ Small fixes
  |     |___________ New features
  |_________________ Major ship releases
```

PS Config Hive provides configuration assistance for other PowerShell modules, scripts, or simply for use directly
from the command line. It allows for easy grouping, retrieval, and override of configuration settings. PS Config Hive
caller is identified automatically using Get-PSCallStack cmdlet or manually set by the caller.

## Features ##
- Automatic detection of caller via Get-PSCallStack separate module configurations separately
- Key value store with different persistence options:
  - No persistence on read. Read every time from source configuration file
  - Session persistence on read. Read once from configuration file, keep configuration on session
  - Expiring cache persistence on read. Read and caches the item using the desired policy (relies on Expiring Cache cmdlets from xUtility module)
    - Allow time specific policy
    - Support generic read policies such that they only return a boolean result that will determine whether to process file IO read or not. Then write a script block for checking if the file has changed in order to reload a configuration
- A basic prevention from accessing specific configuration hives to prevent errors (note that access to the configuration files themselves is different) and the concept of shared configuration objects
- A layer model of configuration objects and configuration overrides
  - Configuration overrides on a session scope level
  - (In evaluation) configuration overrides on a call stack level
- Logging/telemetry (?)

## Design ##
PSConfigHive is designed in layers as follows:

```
 __                          ________________    I   _________
   \- Get-ConfigHive ------ |                |   N  |         |    ____ Local Disk
 -- - Get-ConfigValue ----- |                |   T  |         |---/
 -- - Get-CurrentHiveName - |  PSConfigHive  |-- E--| Storage |
 -- - Get-RegisteredHives - |     Core       |-- R--|   IO    |-------- Remote Web Service
 -- - New-ConfigHive ------ |    Module      |   F  | Adapter |
 -- - Remove-ConfigHive --- |                |   A  |         |---
 -- - Set-ConfigOVerride -- |                |   C  |         |   \____ Encrypted Storage
 __/                        |________________|   E  |_________|
```

>User facing functions are implemented in the core module, these surface specific tasks available to the user. 
They work with either a particular set of data or the whole set (all data in the Hive). Their responsibility is
read and filter or read, modify and save.
A storage adapter deals with whole sets of data (complete hives) that are delivered to the core layer or received
for storage. Its responsibility is to use the desired component to persist the data on a custom implementation for
both the default data set (a hashtable) or a default data definition (a script block) as well as the different 
configuration overrides. A minimum implementation of an adapter will use complete hives for operations, a more
refined adapter will support insert, update, and read operations over single values.

### How to write an IO adapter implementation for PSConfigHive ###
An interface is specified such that adapters can provide specific operations agreed upon

Coming soon...

Configuration data is layered when using overrides as follows:

```

  User <)  <=========================<
              Custom Cache Overrides |
            >------------------------^
            | Session Overrides
            ^------------------------<
              Persistent Overrides   |
            -------------------------^
              Default Configuration
```

>When retrieving a value from the configuration a merge occurs from the multiple layers of data. Starting for the 
default values stored in the configuration, and applying any applicable override on top where the latest override 
value is the one actually surfaced through the user. `Set-ConfigOverride` cmdlet is capable of adding overrides at the 
desired level whereas `Remove-ConfigOverride` removes them. Each layer has its own caracteristics:
- Default configuration is persisted in the media defined by the assigned implementation of the storage adapter
- Persistent overrides are persisted in the same way as the default configuration, note the default values are always
kept
- Session overrides are still handled by the particular adaptor and should only live while the module is loaded in the 
session
- Custom cache overrides validity are subject to a particular policy defined upon creation, this policy can be a time 
policy (i.e. override is valid for an hour) or custom made by the user (takes a `[ScriptBlock]` which returns `$true` 
or `$false`) where the user defines the conditions met to consider it valid

## Proposed List of Cmdlets ##

### Get-CurrentHiveName ###
```
> Get-CurrentHiveName
```
Description:

>Gets the hive name as calculated based on the scope of the caller. This cmdlet inspects the call stack to retrieve
the appropriate scope, it is based on Get-PSCallStack to get the appropriate hierarchy. 
When the caller scope is the console (i.e. console defined functions/script blocks) a default hive name 'ConsoleScope'
is returned by default. 
When the caller is a script file (*.ps1) the hive name returned is the name of the file (i.e. myScript.ps1)
When the caller is a module the hive name returned is the name of the module

Examples:
```
PS> Get-CurrentHiveName
```

```
PS> function func { param(); Get-CurrentHiveName }
PS> func
```

```
PS> $block = { Get-CurrentHiveName }
PS> . $block
```

- Returns the current hive name: 'ConsoleScope' when called from the command line
- Returns the current hive name: 'ScriptName.ps1' when called from within a script file
- Returns the current hive name: 'ModuleName' when called from within a module

### New-ConfigHive ###
```
> New-ConfigHive [-Name [string]] -ConfigBlock [ScriptBlock] [-Adapter [string]]
> New-ConfigHive [-Name [string]] -Config [HashTable] [-Adapter [string]]
```
Description:

>Creates a new config hive. The purpose of this cmdlet is to seed default values for your purposes (module, script, 
or custom). When no overrides are present, values read are retrieved from the data set stored here. These default
values are meant to be persistent and controlled by this module (i.e. you should not need to edit the representation
of this configuration manually). Storage details for the default values is left to the particular implementation of 
the Storage IO layer, see _Design_ section for more details. 
If `-Name` is not specified  the cmdlet calculates the name automatically based on `Get-CurrentHiveName` cmdlet. 
When using `-Config` a HashTable containing the default configuration values is stored and upon reading the selected
value is returned.
When using `-ConfigBlock` the user provides a definition of the mechanism to retrieve the default configuration values.
This is helpful when the user wants to define their own behavior at runtime and thus giving control for the creation
and reading mechanisms. Internally the cmdlet stores the representation of the ScriptBlock and creates a new ScriptBlock
from this representation upon read.

Example:
```
> $defaultConfig = @{
  'Version' = 1
  'Description' = 'Some default config value'
  'TargetServer' = [url] 'https://www.google.com'
}

> New-ConfigHive -Name 'CmdlineConfig' -Config $defaultConfig
```
Creates a default configuration hive under the name of 'CmdlineConfig'

```
> New-ConfigHive -Name 'MyModule' -ConfigBlock { MyModule/Get-DefaultConfig }
```
Creates a configuration hive for a module named 'MyModule', the default values are retrieved by invoking the passed
ScriptBlock. This example allows the module owner to define their defaults and keep them up to date as the module gets
updated (i.e. a new version of the module with updated config values). `New-ConfigHive` will check that return value 
is of `[HashTable]` type.

>Get-RegisteredHives

>Remove-ConfigHive

>Get-ConfigValue

> Get-ConfigHive

> Set-ConfigOverride -Hive -Name -Value -ScopeLevel (Persistent|Session)

> Remove-ConfigOverride

## Requirements ##
- Relies on [PsxUtility](https://www.powershellgallery.com/packages/xUtility) if available (_recommended_)
  - Used for retry operations

## Installation ##
### Cloning this repository ###
This section outlines how to install the module after cloning the repository. Follow these steps to start using the module:
- Clone the repository:
```
> git clone git@github.com:hobelinm/PsConfigHive.git
```
- CD to the location of the module
```
> cd .\PsConfigHive
```
- Import the module
```
> Import-Module -Name .\PsConfigHive.psd1
```

### Using PowerShell Gallery ###

```
> Install-Module -Name PSConfigHive
> Import-Module -Name PSConfigHive
```

## User Guide ##
Coming soon

## Work Items ##
Work items under evaluation:

- Design access model for shared configurations as well as for preventing access when user wants
- Support multi-process access (via retry policy)
- Support session caching
- Abastract storage layer and define a clear implementation (prototype 2 different implementations, CLI XML and Proto Buffers)
- Configuration hives contain metadata that describe the behavior of the access/read such as persistence, permissions, etc.
- Get a list of available adapters
- Set default adapter
- Hives need to have an associated adapter
- Support hive migration(?)
- Adapter data caching:
  - When calling adapter, adapter will use implementation to retrieve data, this data can be cached in multiple ways
  - No caching. Invoke implementation with every call, no issues with mutiple processes accessing
  - Session caching. Read copy live for the session, might have outdated data
  - Expiring cache. Read copy live for an amount of time or as defined by user policy

## Change List ##
```

0.1.2 - Initial module draft, updated documentation, Get-CurrentHiveName
0.1.1 - Updated documentation

```
