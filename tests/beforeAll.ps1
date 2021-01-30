$PlifyModulePath = (Get-Item $PSScriptRoot).Parent.FullName + "$([System.IO.Path]::DirectorySeparatorChar)src$([System.IO.Path]::DirectorySeparatorChar)modules" + [System.IO.Path]::PathSeparator
if ( ($env:PSModulePath).ToLower().Contains($PlifyModulePath.ToLower()) -eq $false ) {
    $env:PSModulePath = $env:PSModulePath + [System.IO.Path]::PathSeparator + $PlifyModulePath
}