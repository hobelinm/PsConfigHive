PowerShell Config Hive
============
A hive for your config needs

Current Version: `0.1.4`

```
Major.Minor.Build
  |     |     |_____ Small fixes
  |     |___________ New features
  |_________________ Major ship releases
```

Config Hive provides configuration tooling for other PowerShell modules, scripts, or simply for use directly
from the command line. It allows for easy grouping, retrieval, and override of configuration settings. 
Config Hive requires [xUtility](https://www.powershellgallery.com/packages/xUtility) module. 
If the module is not available in the system it will be installed during prompt. 
xUtility allows Config Hive better recovery and behavior scenarios by leveraging two features mainly:
- Expiring cache (allows not to query the source every on every access)
- Retry Logic (used for storage operation that are flaky)

## Features ##
- Extensible Key/Value store with configurable caching options
  - Caching is based per hive and level of override
- Multiple override levels allow fine control over the changes to configuration objects
  - System wide, User wide, Session Wide override levels

## Design ##
ConfigHive is designed in layers as follows:

```
 __                          ________________        _________
   \- Get-ConfigHive ------ |                |   I  |         |
 -- - Get-ConfigValue ----- |                |   N  |         |    ____ Local Disk
 -- - Get-CurrentHiveName - |                |   T  |         |---/
 -- - Get-RegisteredHives - |  PSConfigHive  |   E  | Storage |
 -- - New-DataStore       - |     Core       |-- R--|   IO    |
 -- - Register-ConfigHive - |    Module      |-- F--| Adapter |-------- Remote Web Service
 -- - Remove-ConfigHive --- |                |   A  |         |
 -- - Set-ConfigHive ------ |                |   C  |         |---
 -- - Set-ConfigOVerride -- |                |   E  |         |   \____ Encrypted Storage
 __/                        |________________|      |_________|
```

> User functions are listed on the left, these are exposed directly by the module. On the right the store implementations
outlines the primary function for those as well as to how they interact with the module.

### How to write an IO adapter implementation for ConfigHive ###
An interface is specified such that adapters can provide specific operations agreed upon

Coming soon...

Configuration data is layered when using overrides as follows:

```

  User <)  <=========================<
                Session Overrides     |
            >------------------------^
            |     User Overrides
            ^------------------------<
                 System Overrides     |
            -------------------------^
            |  Default Configuration
            --------------------------
```

```
[For each registered hive]:

  ___________    ________________________    _______________
 |  Seeded  |   | Applied       Applied  |   |   Applied    |
 |   ____   |   |  _____         ____    |   |    ____      |
 |  |   |\  | + |  |   |\   +    |   |\  | + |   |   |\     |
 |  |    | ------> |    |  --->  |    | -------> |    |  =====>  Result Value
 |  |____|  |   |  |____|        |____|  |   |   |____|     |
 |__________|   |________________________|   |______________|
 | Original |   | System         User    |   |   Session    |
 Configuration  |Overrides     Overrides |   |  Overrides   |
 |    ||    |   |   ||            ||     |   |     ||       |
 |  Cache   |   | Cache          Cache   |   |    Cache     |
 |    ||    |   |   ||            ||     |   |     ||       |
 |  Policy  |   | Policy        Policy   |   |   Policy     |
 |----------|   |------------------------|   |--------------|
 |< Module >|   |<   Storage Adapter    >|   |< ConfigHive >|
 |__________|   |________________________|   |______________|

```

> When retrieving values the module reads from the upper layers looking for the first colliding override. On each layer 
the module interrogates the associated store for an override. The store for each specific layer is associated when 
registering the Configuration Hive. Each store contains its own caching policy and controls their own cache according 
to the given initialization parameters during the Hive Registration. Each Configuration Hive contains a specific instance 
of a store for each layer amongst the available stores, therefore removing a store used on a registered Configuration Hive
will cause issues. If no colliding override is found the original value is used. 
There are two ways of seeding default values into a previously registered config hive:
- Permanently, stores the values into the given store instance. This option is suitable for settings that do not change 
often, as re-seeding values would be more more expensive this operation should be reserved for values more or less constant
- In-memory store, allows to follow changes to original configuration values, for example further releases of scripts or 
modules using the Config Hive which contain changes. This operation is recommended for most modules and typically is done 
during the load of the module as it does not involve IO operations other than memory.

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
- Support hive migration(v2?)
- Logging/telemetry (v2?)
- Automatic check for updates
- Adapter data caching:
  - When calling adapter, adapter will use implementation to retrieve data, this data can be cached in multiple ways
  - No caching. Invoke implementation with every call, no issues with mutiple processes accessing
  - Session caching. Read copy live for the session, might have outdated data
  - Expiring cache. Read copy live for an amount of time or as defined by user policy

## Metrics to Collect
- Module Version
- Module installed on
- Load module event
- Number of folders created
- Time to load of core functions
- Time to load of custom stores
- Overall time to load
- Execution time for all functions (along with their store id)
- Number of folders created
- Time since last run
- Number of custom stores
- OS Architecture
- PS Version

## Change List ##
```

0.1.4 - Updated pattern to support multiple OS, loading message
0.1.3 - Renamed module, documentation update
0.1.2 - Initial module draft, updated documentation, Get-CurrentHiveName
0.1.1 - Updated documentation

```
