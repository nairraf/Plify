# Global Variables
$Global:ds = ([system.io.path]::DirectorySeparatorChar)

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
    foreach ($file in (Get-ChildItem -Path "$PSScriptRoot$($ds)*.ps1" -Exclude "bootstrap.ps1" -Recurse)) {
        Write-Verbose "importing $($file.FullName)"
        . $file.FullName
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
    Import-PlifyFunctions
    Set-PlifyModuleRoots
    PlifyConfig\Initialize-PlifyConfig -Scope "Global"
}