#Requires -Modules powershell-yaml
param(
    [Parameter(Mandatory=$false, Position=0)] [string] $Module,
    [Parameter(Mandatory=$false, Position=1)] [string] $Action,
    [Parameter(Mandatory=$false, Position=2)] [hashtable] $ActionParams,
    [Parameter(Mandatory=$false)] [switch] $Help,
    [Parameter(Mandatory=$false)] [switch] $Flush
)

# bootstrap
## update Module Path
$PlifyModulePath = $PSScriptRoot + "$([System.IO.Path]::DirectorySeparatorChar)modules" + [System.IO.Path]::PathSeparator
if ( ($env:PSModulePath).ToLower().Contains($PlifyModulePath.ToLower()) -eq $false ) {
    $env:PSModulePath = $env:PSModulePath + [System.IO.Path]::PathSeparator + $PlifyModulePath
}

# we import modules on demand - no preloading
# so flush will import all modules, then remove them so that the ones that are re-loaded are fresh
if ($Flush) {
    Get-Module -Name Plify* | Import-Module
    Remove-Module Plify*
}

# route requests via naming convention
if ( -not [string]::IsNullOrEmpty($Module) ) {
    $ModuleName = PlifyRouter\Build-PlifyModuleName -ModuleName $Module

    # see if we can find a module of that name
    $ModuleFound = PlifyRouter\Get-PlifyModule -ModuleName $ModuleName

    if ($null -ne $ModuleFound) {
        Write-Debug "Found Module: $($ModuleFound.Name)"
        if ( -not [string]::IsNullOrEmpty($Action)) {
            $ActionName = PlifyRouter\Build-PlifyActionName -Module $ModuleFound -ActionName $Action
            $ActionFound = PlifyRouter\Get-PlifyModuleAction -Module $ModuleFound -ActionName $ActionName
            if ($null -ne $ActionFound) {
                Write-Debug "Found Action: $($ActionFound.Name)"
            }
        }
    }
}

if ($null -eq $ModuleFound -or $null -eq $ActionFound) {
    $Help = $true
}

## see if help has been requested
if ($Help) {
    if ( $null -ne $ModuleFound -and $null -eq $ActionFound) {
        $HelpModule = "$($ModuleFound.Name)\Get-$($ModuleFound.Name)Help"
        Write-Debug "Getting Default Module Help: $HelpModule"
        & $HelpModule
        Exit
    } 
    
    if ($null -ne $ModuleFound -and $null -ne $ActionFound) {
        Write-Debug "Getting Module Help Action: $($ModuleFound.Name)\$ActionFound -Help"
        & $($ModuleFound.Name)\$ActionFound -Help 
        Exit
    }

    PlifyHelp\Get-PlifyHelp
    Exit
}

# call the requested module, action and pass on action parameters
try {
    if ($ActionParams) {
        Write-Debug "Executing: $($ModuleFound.Name)\$($ActionFound.Name) $ActionParams"
        & $($ModuleFound.Name)\$ActionMatch @ActionParams
    } else {
        Write-Debug "Executing: $($ModuleFound.Name)\$($ActionFound.Name)"
        & $($ModuleFound.Name)\$ActionFound
    }
} catch {
    Write-Error "unknown module: $($ModuleFound.Name) and/or action $($ActionFound.Name)"
}