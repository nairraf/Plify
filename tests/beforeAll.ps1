param (
    [Parameter(Mandatory=$false)] [bool] $CallInvoke = $true
)

.  "$((Get-Item $PSScriptRoot).Parent.FullName)$([System.IO.Path]::DirectorySeparatorChar)src$([System.IO.Path]::DirectorySeparatorChar)functions$([System.IO.Path]::DirectorySeparatorChar)bootstrap.ps1"

if ($CallInvoke) {
    Invoke-PlifyBootstrap
}