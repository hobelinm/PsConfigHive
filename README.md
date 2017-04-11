PowerShell Config Hive
============
A hive for your config needs

Current Version: `0.1.1`

```
Major.Minor.Build
  |     |     |_____ Small fixes
  |     |___________ New features
  |_________________ Major ship releases
```

PS Config Hive provides configuration assistance for other PowerShell modules, scripts, or simply for use directly
from the command line. It allows for easy grouping, retrieval, and override of configuration settings. PS Config Hive
caller is identified automatically using Get-PSCallStack cmdlet or manually set by the caller.

## Features
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

## Requirements
- Relies on [PsxUtility](https://www.powershellgallery.com/packages/xUtility) if available (_recommended_)
  - Used for retry operations

## Installation
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
> Import-Module .\PsConfigHive.psd1
```
- _Alternatively_ you can setup the module in your system:
```
> .\Setup.ps1
```
- Then the module should be available in every PowerShell session afterwards regardless of the path
```
> Import-Module -Name PsConfigHive
```

### Using PowerShell Gallery ###

```
> Install-Module -Name PSConfigHive
> Import-Module -Name PSConfigHive
```

## User Guide
Coming soon

## Work Items
Work items under evaluation:

- Design access model for shared configurations as well as for preventing access when user wants
- Support multi-process access (via retry policy)
- Support session caching
- Abastract storage layer and define a clear implementation (prototype 2 different implementations, CLI XML and Proto Buffers)
- Configuration hives contain metadata that describe the behavior of the access/read such as persistence, permissions, etc.

## Change List
```

0.1.1 - Updated documentation

```
