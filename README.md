# PSDefaults

[![powershellgallery](https://img.shields.io/powershellgallery/v/PSDefaults.svg)](https://www.powershellgallery.com/packages/PSDefaults)
[![downloads](https://img.shields.io/powershellgallery/dt/PSDefaults.svg?label=downloads)](https://www.powershellgallery.com/packages/PSDefaults)
[![build](https://img.shields.io/travis/felixfbecker/PSDefaults/master.svg)](https://travis-ci.org/felixfbecker/PSDefaults)
![platform](https://img.shields.io/powershellgallery/p/PSDefaults.svg?colorB=blue)
[![codecov](https://codecov.io/gh/felixfbecker/PSDefaults/branch/master/graph/badge.svg)](https://codecov.io/gh/felixfbecker/PSDefaults)

PowerShell wrapper around the macOS [`defaults` utility](https://rixstep.com/2/20060901,00.shtml).

- Allows you to manage preferences of macOS and macOS applications, e.g. to completely automate setting up a Mac.
- Merges settings from the system, network, local and user level.
- Values are represented in native PowerShell types, which means you can even manage deeply nested dictionaries.
- Full autocompletion for domains and keys.
- Full test coverage, for all data types.

## Installation

```powershell
Install-Module PSDefaults
```

## Examples

Get all domains:

```powershell
Get-DefaultsDomain
```

Get all Apple Mail settings:

```powershell
Get-DefaultsValue -Domain com.apple.mail
```

Get the current setting for showing the CC field in Apple Mail:

```powershell
Get-DefaultsValue -Domain com.apple.mail -Key ShowCcHeader
```

Enable the current setting for showing the CC field in Apple Mail:

```powershell
Set-DefaultsValue -Domain com.apple.mail -Key ShowCcHeader -Value 1
```

Remove a domain, e.g. after uninstalling a certain application:

```powershell
Remove-DefaultsDomain us.zoom.xos
```

Reset a setting to the default:

```powershell
Remove-DefaultsValue -Domain com.apple.mail -Key ShowCcHeader
```

## Data Types

| `defaults` type | PowerShell type |
| --------------- | --------------- |
| array           | `[array]`       |
| dict            | `[hashtable]`   |
| string          | `[string]`      |
| data            | `[byte[]]`      |
| date            | `[datetime]`    |
| integer         | `[bigint]`      |
| real            | `[double]`      |
| boolean         | `[bool]`        |
