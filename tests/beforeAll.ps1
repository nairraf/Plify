$PlifyModulesRoots = Get-ChildItem -Path ( (Get-Item $PSScriptRoot).Parent.FullName + "$([System.IO.Path]::DirectorySeparatorChar)src$([System.IO.Path]::DirectorySeparatorChar)modules") -Directory

foreach ($PlifyPath in $PlifyModulesRoots.FullName) {
    if ( -not ($env:PSModulePath).ToLower().Contains($PlifyPath.ToLower()) ) {
        $env:PSModulePath = $env:PSModulePath + [System.IO.Path]::PathSeparator + $PlifyPath
    }
}