param (
    [Parameter(Mandatory=$false)] [bool] $CallInvoke = $true
)

# make sure that we remove all loaded plify Modules to make sure we are testing the latest code
Get-Module -Name Plify* | Remove-Module

$ds = [System.IO.Path]::DirectorySeparatorChar
.  "$((Get-Item $PSScriptRoot).Parent.FullName)$($ds)src$($ds)functions$($ds)bootstrap.ps1"

if ($CallInvoke) {
    Reset-Plify
}