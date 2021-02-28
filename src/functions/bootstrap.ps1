
function Initialize-PlifyGlobals() {
    $Global:ds = ([system.io.path]::DirectorySeparatorChar)
    . "$PSScriptRoot$($ds)PlifyGlobals.ps1"
}

<#
.SYNOPSIS
Main function to import all the required Plify functions

.EXAMPLE
. functions\bootsrap.ps1
Invoke-PlifyBootstrap

.NOTES
Invoke-PlifyBootstrap calls Import-PlifyFunctions so you do not have to call this manually
#>
function Import-PlifyFunctions() {
    foreach ($file in (Get-ChildItem -Path "$PSScriptRoot$($ds)*.ps1" -Exclude "bootstrap.ps1","PlifyGlobals.ps1" -Recurse)) {
        Write-Verbose "importing $($file.FullName)"
        . $file.FullName
    }
}

function Reset-Plify() {
    param (
        [Parameter(Mandatory=$false)] [bool] $ReBootStrap = $true
    )

    Write-Debug "Removing Plify Modules from current Scope"
    Get-Module -Name Plify* | Import-Module
    Remove-Module Plify*
    Write-Debug "Removing Plify Functions from current Scope"
    Get-Item -Path Function:\*Plify* | Remove-Item -ErrorAction SilentlyContinue
    if ($ReBootStrap) {
        Write-Debug "Re-Bootstrapping Plify functions and modules"
        # since we removed all plify functions and modules, we need to source the current file back into local scope
        . $PSCommandPath
        Invoke-PlifyBootstrap
        Update-FormatData
    }
}

<#
.SYNOPSIS
Main BootStrap Function to bootstrap plify

.EXAMPLE
. functions\bootsrap.ps1
Invoke-PlifyBootstrap
#>
function Invoke-PlifyBootstrap() {
    $error.Clear()
    Initialize-PlifyGlobals
    Import-PlifyFunctions
    Set-PlifyModuleRoots
    Update-PlifyFormatData
    PlifyConfiguration\Initialize-PlifyConfiguration -Scope "Global"
}