<#
.SYNOPSIS
Updates the PowerShell Module path to make sure that Plify modules can be found when using commands like Get-Module, Remove-Module

.EXAMPLE
. functions\bootstrap.ps1
Invoke-PlifyBootstrap
Set-PlifyModulePath
#>
function Global:Set-PlifyModuleRoots() {
    $PlifyModuleRoots = Get-ChildItem -Path ( (Get-Item $PSScriptRoot).Parent.FullName + "$([System.IO.Path]::DirectorySeparatorChar)modules" ) -Directory

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
    $sep = [System.IO.Path]::DirectorySeparatorChar
    $curModPath = $env:PSModulePath.split([System.IO.Path]::PathSeparator)
    $newModPath = @()
    $PlifyBases = @( 
        "Plify$($sep)src$($sep)modules$($sep)app", 
        "Plify$($sep)src$($sep)modules$($sep)core", 
        "Plify$($sep)src$($sep)modules$($sep)managers" 
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