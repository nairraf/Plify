#Requires -Modules powershell-yaml
using module .\..\..\..\types\PlifyBase.types.psm1

# import all our external module functions into the modules current scope on module load
foreach ($file in (Get-ChildItem -Path "$PSScriptRoot$($ds)*.ps1" -Recurse)) {  
    . $file.FullName
}

<#
.SYNOPSIS
Loads a valid plify local configuraion from a YAML file

.PARAMETER RawYaml
a string containing the raw YAML 
#>
function Get-PlifyConfigurationFromYaml() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $RawYaml
    )
    
    # must contain RootDirectory and at least one of Networks and/or VirtualMachines
    $plifyConfig = ConvertFrom-Yaml -Yaml $RawYaml
    if ($plifyConfig.Keys.Count -gt 0 -and $plifyConfig.Keys -Contains "rootdirectory" -and ($plifyConfig.Keys -Contains "networks" -or $plifyConfig.Keys -Contains "virtualmachines") ) {
        return $plifyConfig
    }
}

function Get-PlifyConfigurationDir() {
    param (
        [Parameter(Mandatory=$false, Position=0)] [string] $Scope = "local",
        [Parameter(Mandatory=$false, Position=1)] [string] $DirName = "Plify"
    )

    if ($Scope -eq "global") {
        $localAppData = (Get-Item $env:LOCALAPPDATA).FullName
        return "$localAppData$($ds)$($DirName)"
    } else {
        $curDir = (Get-Location).Path
        return "$curDir$($ds).$($DirName)"
    }
}

<#
.SYNOPSIS
Initializes the default Plify config for local and global scopes

.PARAMETER Scope
Scope should be Local or Global. Be default the scope is local.
Global scope creates the default Global config.yml file
Local scope (default) creates .plifi/config.yml in the current working directory

.EXAMPLE
plifi config init
#>
function Initialize-PlifyConfiguration() {
    param (
        [Parameter(Mandatory=$false, Position=0)] [string] $Scope = "local"
    )

    $PlifyConfigDir = Get-PlifyConfigurationDir $Scope
    if ( -not (Test-Path -Path $PlifyConfigDir) ) {
        Write-Output "Initializing $Scope Plify config dir: $PlifyConfigDir"
        New-Item -Path $PlifyConfigDir -ItemType "directory" | Out-Null
    }

    # make sure that we have a config file
    if (-not (Test-Path -Path "$PlifyConfigDir$($ds)config.yml")) {
        Write-Output "Creating default $Scope Plify Configuration: $PlifyConfigDir$($ds)config.yml"
        if ($Scope -eq "local") {
            # Create default local config.yml
        }

        if ($Scope -eq "global") {
            ConvertTo-Yaml -Data $defaultPlifyConfigGlobal -OutFile "$PlifyConfigDir$($ds)config.yml" -Force
        }
    }
}

function Get-PlifyConfiguration() {
    param(
        [Parameter(Mandatory=$false)] [string] $Scope = "Local",
        [Parameter(Mandatory=$false)] [string] $RootElement = $null,
        [Parameter(Mandatory=$false)] [switch] $ConvertToPS
    )

    $configDir = Get-PlifyConfigurationDir -Scope $Scope
    $configFile = "$configDir$($ds)config.yml"

    if ( Test-Path -Path $configFile ) {
        $content = Get-Content $configFile -Raw

        # we convert to PS types if requested or if a RootElement has been requested
        if ( $ConvertToPS -or [string]::IsNullOrEmpty($RootElement) -eq $false) {
            $content = ConvertFrom-Yaml $content
        }

        # if a Root element has been requested and exists, return just that root element
        if ([string]::IsNullOrEmpty($RootElement) -eq $false -and $content.keys -contains $RootElement) {
            $elementContent = @{}
            $elementContent[$RootElement] = $content[$RootElement]
            $content = $elementContent
            $elementContent = $null
        }

        return $content
    }
}

function Show-PlifyConfiguration() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)] [string] $Scope = "Local",
        [Parameter(Mandatory=$false)] [string] $RootElement = $null
    )

    Get-PlifyConfiguration -Scope $Scope -RootElement $RootElement

    return [Plify]::new()
}

function Set-PlifyGlobalConfig() {
    param(
        [Parameter(Mandatory=$true)] [hashtable] $config,
        [Parameter(Mandatory=$false)] [string] $RootElement = $null
    )

    $configDir = Get-PlifyConfigurationDir -Scope "Global"
    $configFile = "$configDir$($ds)config.yml"

    # if a RootElement has been set, then just update that RootElement only
    if ( -not [string]::IsNullOrEmpty($RootElement)) {
        $fullConfig = Get-PlifyConfiguration -Scope "Global" -ConvertToPS
        $fullConfig[$RootElement] = $config[$RootElement]
        $config = $fullConfig
    }

    ConvertTo-Yaml -Data $config -OutFile $configFile -Force
}