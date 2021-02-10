<#
.SYNOPSIS
Updates the PowerShell Module path to make sure that Plify modules can be found when using commands like Get-Module, Remove-Module

.EXAMPLE
. functions\bootstrap.ps1
Invoke-PlifyBootstrap
Set-PlifyModulePath
#>
function Global:Set-PlifyModuleRoots() {
    $PlifyModuleRoots = Get-ChildItem -Path ( (Get-Item $PSScriptRoot).Parent.FullName + "$($ds)modules" ) -Directory

    foreach ($PlifyPath in $PlifyModuleRoots.FullName) {
        if ( -not ($env:PSModulePath).ToLower().Contains($PlifyPath.ToLower()) ) {
            $env:PSModulePath = $env:PSModulePath + [System.IO.Path]::PathSeparator + $PlifyPath
        }
    }
}

<#
.SYNOPSIS
Removes Plify Module Directories from Powershell Module Path

.EXAMPLE
. functions\bootstrap.ps1
Invoke-PlifyBootstrap
Remove-PlifyModuleRoots
#>
function Global:Remove-PlifyModuleRoots() {
    $curModPath = $env:PSModulePath.split([System.IO.Path]::PathSeparator)
    $newModPath = @()
    $PlifyBases = @( 
        "Plify$($ds)src$($ds)modules$($ds)app", 
        "Plify$($ds)src$($ds)modules$($ds)core", 
        "Plify$($ds)src$($ds)modules$($ds)managers" 
    )
    foreach ($dir in $curModPath) {
        $addToModulePath = $true
        foreach ($plifyRoot in $PlifyBases) {
            if ( $dir.Contains( $plifyRoot ) ) {
                $addToModulePath = $false
            }
        }

        if ($addToModulePath) {
            $newModPath += $dir
        }
    }
    $env:PSModulePath = ($newModPath -join [System.IO.Path]::PathSeparator)
}