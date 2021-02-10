#Requires -Modules powershell-yaml

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
function Get-PlifyConfigFromYaml() {
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

function Get-PlifyConfigDir() {
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
function Initialize-PlifyConfig() {
    param (
        [Parameter(Mandatory=$false, Position=0)] [string] $Scope = "local"
    )

    $PlifyConfigDir = Get-PlifyConfigDir $Scope
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
            # Create default global config.yml
            #$defaultYaml = ConvertFrom-Yaml -Yaml $DefaultGlobalConfigYaml
            $defaultConfig = @{
                Repositories = @{ 
                    'Dev Plify Repository'='devrepo.plify.xyz'; 
                    'Official Production Plify Repository'='repo.plify.xyz' }
            }
            ConvertTo-Yaml -Data $defaultConfig -OutFile "$PlifyConfigDir$($ds)config.yml" -Force
        }
    }
}

function Get-PlifyConfig() {
    param(
        [Parameter(Mandatory=$false)] [string] $Scope = "Local",
        [Parameter(Mandatory=$false)] [switch] $ConvertToPS
    )

    $configDir = Get-PlifyConfigDir -Scope $Scope
    $configFile = "$configDir$($ds)config.yml"

    if ( Test-Path -Path $configFile ) {
        $content = Get-Content $configFile -Raw
        if ($ConvertToPS) {
            $content = ConvertFrom-Yaml $content
        }
        return $content
    } else {
        return "Config File Not found: $configFile"
    }
}

function Set-PlifyGlobalConfig() {
    param(
        [Parameter(Mandatory=$true)] [hashtable] $config
    )

    $configDir = Get-PlifyConfigDir -Scope "Global"
    $configFile = "$configDir$($ds)config.yml"

    ConvertTo-Yaml -Data $config -OutFile $configFile -Force
}

Export-ModuleMember -Function Get-PlifyConfigFromYaml,Initialize-PlifyConfig,Get-PlifyConfigDir,Get-PlifyConfig,Set-PlifyGlobalConfig