PowerShell Config Hive
============
A hive for your config needs

Current Version: `1.0.3`
Release Code Name: `2-1B`

```
Major.Minor.Build
  |     |     |_____ Small fixes
  |     |___________ New features
  |_________________ Major ship releases
```

Config Hive provides configuration tooling for other PowerShell modules, scripts, or simply for use directly
from the command line. It allows for easy grouping, retrieval, and override of configuration settings. 
Config Hive requires [xUtility](https://www.powershellgallery.com/packages/xUtility) module. 
If the module is not available it will be installed during first run. 
xUtility allows Config Hive better recovery and behavior scenarios by leveraging two features:
- Expiring cache (allows not to query the source every on every access)
- Retry Logic (used for storage operation that might be flaky File IO: Simultaneous file access, Network connection, etc.)

## Features ##
- Extensible Key/Value store with configurable caching options
  - Caching is based per hive and level of override
- Multiple override levels allow fine control over the changes to configuration objects
  - System wide, User wide, Session Wide override levels
- Shipped with two available data stores:
  - In-memory data store: 'MemStore'
  - File serialization data store: 'CliFileStore'

## Design ##
ConfigHive is designed in layers as follows:

```
 __                           ________________        _________
   \- Get-ConfigHive ------- |                |   I  |         |
 -- - Get-ConfigValue ------ |                |   N  |         |    ____ Local Disk
 -- - Get-CurrentHiveName -- |                |   T  |         |---/
 -- - Get-RegisteredHives -- |  PSConfigHive  |   E  | Storage |
 -- - New-DataStore -------- |     Core       |-- R--|   IO    |
 -- - Register-ConfigHive -- |    Module      |-- F--| Adapter |-------- Remote Web Service
 -- - Unregiste-ConfigHive - |                |   A  |         |
 -- - Set-ConfigHive ------- |                |   C  |         |---
 -- - Set-ConfigOVerride --- |                |   E  |         |   \____ Encrypted Storage
 __/                         |________________|      |_________|
```

> User functions are listed on the left, these are exposed directly by the module. On the right the store implementations
outlines the primary function for those as well as to how they interact with the module.

### How to write an IO adapter implementation for ConfigHive ###
Config Stores create a derived implementation of a defined abstract class that outlines the methods available for use 
within the module. To create a new Config Store implementation follow these steps:
- Create a class that is derived from ConfigBaseStore: `MyConfigStore : ConfigBaseStore`
- Update the base constructor of `ConfigBaseStore` to provide the specified parameters
  - `[string] ` Name of the store
  - `[Version]` Version of the store
  - `[string] ` Name of the associated Hive to be used with
- Implement the methods described in the abstract class `ConfigBaseStore` as follows:
  - New Instance. Equivalent to Clone operation creates a new instance of the store. This is used by `New-DataStore` function
```powershell
[ConfigBaseStore] NewInstance([string] $HiveName)
```
  - Rehydrate. A method that creates a new instance of the store based on serialized data
```powershell
[ConfigBaseStore] Rehydrate([string] $SerializedData)
```
  - Set custom parameters. Allows to pass any custom parameters for initializing the store. This might be required by some 
stores such as REST based stores or others where additional data is required such as Authentication, Username/Passwords, or 
specific storage locations. This information is expected to be provided either by the user manually or by custom modules that 
rely on ConfigHive to store their configurations
```powershell
[void] SetCustomParams($CustomParams)
```
  - An option to enforce custom parameters. Return true to enforce additional custom parameters and false to leave them optional
```powershell
[bool] RequiresCustomParams()
```
  - Initialize Store. Takes a `[HashTable]` and initializes the store to a default set of values
```powershell
[void] InitializeStore([HashTable] $Values)
```
  - Read a single value from the store. To give a deterministic value in the class we're using a HashTable which must have 
a key named '`Value`' that holds the value to return back
```powershell
[HashTable] GetValue([string] $Key)
```
  - Set/Override a single value on the store
```powershell
[void] SetValue([string] $Key, $Value)
```
  - Removes an existing value from the store
```powershell
[void] RemoveValue([string] $Key)
```
  - Gets a list of the keys in the store
```powershell
[string[]] GetKeys()
```
  - Serialize bootstrap data in order to create new instances of the store
```powershell
[string] SerializeInstanceData()
```


- In the `.ps1` file where the class is defined (which will be dot sourced during module bootstrapping) the newly registered 
class needs to be made available to the module by adding its class name `[type]` to a global list of available Config Stores. 
This can be achieved by including a modified version (according to the new type being registered) of the following snippet:
```powershell
$Script:AvailableStores += 'MyOwnConfigStore'
```
- It is recommended to include this snippet at the end of the `*.ps1` file to allow for the class to load first
- The location of the `*.ps1` file(s) is to be placed on destination marked by the following command:
```powershell
Get-CustomStorePath
```
The module does not search recursively on subfolders and dot-sourcing every file on the directory tree. Rather it opens 
the first level directories in the location and dot-source any `*.ps1` files in each sub-directory. Further sub-directories 
are not checked by design to allow for the following design pattern:

```
  Stores Folder ------- ConfigStore1 --- ConfigStore.ps1
                   |                  |- MainFolder ------- ... Additional Files
                   |--- ConfigStore2 ...
                   |
                  ...
 _______________      ________________  __________________  ______________________
 |              |     |               | |                 | |                     |
 |   Stores     |     |     Store     | |  *.ps1 Files    | |   Ignored Content   |
 |  Directory   |     |   Directory   | |     Loaded      | |                     |
 |              |     |   (Scanned)   | |     Rest is     | |                     |
 |              |     |               | |     Skipped     | |                     |
 |______________|     |_______________| |_________________| |_____________________|

```
> This design allows for community driven repositories that can be cloned to *Stores Folder* and used directly.


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

## Usage ##
Usage details are included in the module they include a description as well as examples, use:
```powershell
Get-Help <function name> -Full
```

## Requirements ##
- Relies on [PsxUtility](https://www.powershellgallery.com/packages/xUtility) if available (_recommended_)
  - Used for retry operations

## Installation ##
### Cloning this repository ###
This section outlines how to install the module after cloning the repository. Follow these steps to start using the module:
- Clone the repository:
```bash
git clone git@github.com:hobelinm/PsConfigHive.git
```
- CD to the location of the module
```bash
cd .\PsConfigHive
```
- Import the module
```powershell
Import-Module -Name .\PsConfigHive.psd1
```

### Using PowerShell Gallery ###

```powershell
Install-Module -Name ConfigHive
Import-Module -Name ConfigHive
```

## User Guide ##

### Example 1 ###
Create a Cli file store for User level, and register a config hive for 'Console'
```powershell
$str1 = New-DataStore -HiveName 'Console' -StoreName 'CliFileStore' -StoreLevel 'User' -Options ([TimeSpan] '0:0:5')
Register-ConfigHive -HiveName 'Console' -UserStore $str1
```

### Example 2 ###
Using previously registered hive `'Console'` add multiple values to different levels
```powershell
# Sets a value stored on a serialized file under 'Description' key
Set-ConfigValue -Key 'Description' -Value 'Console User Level Setting' -HiveName 'Console' -Level 'User'
# Sets value at Origin level
Set-ConfigValue -Key 'Test' -Value 'TestOrigin' -HiveName 'Console' -Level 'Origin'
# Override value at System level
Set-ConfigValue -Key 'Test' -Value 'TestSystem' -HiveName 'Console' -Level 'System'
# Return highest override (System):
Get-ConfigValue -Key 'Test' -HiveName 'Console'
# Returns:
TestSystem
# Value at Origin level is still preserved:
Get-ConfigValue -Key 'Test' -HiveName 'Console' -Level 'Origin'
# Returns:
TestOrigin
# Sets random values on Origin and System levels:
Set-ConfigValue -Key 'Test1' -Value 'TestOrigin1' -HiveName 'Console' -Level 'Origin'
Set-ConfigValue -Key 'Test2' -Value 'TestSystem2' -HiveName 'Console' -Level 'System'
# Retrieve the values stored currently on the configuration hive, you can see how overrides are applied:
Get-ConfigHive -HiveName 'Console'
# Returns:
Name                           Value
----                           -----
Test2                          TestSystem2
Test                           TestSystem
Test1                          TestOrigin1
Description                    Console User Level Setting

# Key values can be retrieved
Get-ConfigKeys -HiveName 'Console'
# Returns:
Description
Test2
Test
Test1

```

See `./test.ps1` for more examples

## Work Items ##
Work items under evaluation:

- Logging/telemetry (v2?)
- Git repository for stores (v2?)
- Set read-only values for a store (v2?)
- Register-ConfigHive (Add option for register globally v2)

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
- Time for each cmdlet to complete

## Change List ##
```
1.0.3 - Updated GetAppDataPath to avoid coliding with xUtility/Get-AppDataPath
1.0.2 - Get-ConfigKeys to accept [string] $Key to filter for a specific key
1.0.1 - Fixed issue with [CliFileStore]::GetKeys() that doest not initialize Cli file before use
1.0.0 - CliFileStore options are not mandatory, Cli file to use can be overrided via options. First Release (2-1B)
0.2.1 - Automatic check for updates
0.2.0 - First functional version
0.1.4 - Updated pattern to support multiple OS, loading message
0.1.3 - Renamed module, documentation update
0.1.2 - Initial module draft, updated documentation, Get-CurrentHiveName
0.1.1 - Updated documentation

```
