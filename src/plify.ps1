#Requires -Modules powershell-yaml
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, Position=0)] [string] $Module,
    [Parameter(Mandatory=$false, Position=1)] [string] $Action,
    [Parameter(Mandatory=$false, Position=2)] [hashtable] $ActionParams = @{},
    [Parameter(Mandatory=$false)] [switch] $Help,
    [Parameter(Mandatory=$false)] [switch] $Flush
)

# bootstrap
## update Module Path
$PlifyModulesRoots = Get-ChildItem -Path ($PSScriptRoot + "$([System.IO.Path]::DirectorySeparatorChar)modules") -Directory

foreach ($PlifyPath in $PlifyModulesRoots.FullName) {
    if ( -not ($env:PSModulePath).ToLower().Contains($PlifyPath.ToLower()) ) {
        $env:PSModulePath = $env:PSModulePath + [System.IO.Path]::PathSeparator + $PlifyPath
    }
}

# we import modules on demand - no preloading
# so flush will import all modules, then remove them so that the ones that are re-loaded are fresh
if ($Flush) {
    Get-Module -Name Plify* | Import-Module
    Remove-Module Plify*
}

# test if we have a verbose or debug flag and pass it on so modules can use them
$extraFlags = @{
    Verbose = if ($PSBoundParameters.Verbose -eq $true) {$true} else {$false};
    Debug = if ($PSBoundParameters.Debug -eq $true) {$true} else {$false};
}

# get friendly output for the $ActionParams dictionary
$ActionParamsString = PlifyUtils\Build-PlifyStringFromHash $ActionParams

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

# see if we found a valid module/action, if not redirect to help
if ($null -eq $ModuleFound -or $null -eq $ActionFound) {
    $Help = $true
}

## see if help has been requested, if so display help and exit
if ($Help) {
    if ( $null -ne $ModuleFound -and $null -eq $ActionFound) {
        Write-Debug "Getting Help for Module: $($ModuleFound.Name)"
        PlifyHelp\Get-PlifyHelp -Module $ModuleFound.Name @extraFlags
        Exit
    } 
    
    if ($null -ne $ModuleFound -and $null -ne $ActionFound) {
        Write-Debug "Getting Help for Module\Action: $($ModuleFound.Name)\$($ActionFound.Name)"
        PlifyHelp\Get-PlifyHelp -Module $ModuleFound.Name -Action $ActionFound.Name @extraFlags
        Exit
    }

    PlifyHelp\Get-PlifyHelp @extraFlags
    Exit
}

# call the requested module, action and pass on action parameters
try {
    if ($ActionParams.Count -gt 0) {
        Write-Debug "Executing: $($ModuleFound.Name)\$($ActionFound.Name) $ActionParamsString"
        & $ModuleFound\$ActionFound @ActionParams @extraFlags
    } else {
        Write-Debug "Executing: $($ModuleFound.Name)\$($ActionFound.Name)"
        & $ModuleFound\$ActionFound @extraFlags
    }
} catch {
    Write-Error -Message "Error Executing: $($ModuleFound.Name)\$($ActionFound.Name) $ActionParamsString"
}