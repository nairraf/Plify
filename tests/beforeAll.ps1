param (
    [Parameter(Mandatory=$false)] [bool] $CallInvoke = $true
)
    $ds = [System.IO.Path]::DirectorySeparatorChar
.  "$((Get-Item $PSScriptRoot).Parent.FullName)$($ds)src$($ds)functions$($ds)bootstrap.ps1"

if ($CallInvoke) {
    Invoke-PlifyBootstrap
}