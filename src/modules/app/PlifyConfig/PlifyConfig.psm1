#Requires -Modules powershell-yaml

function Get-PlifyConfigFromYaml() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $RawYaml
    )

    # must contain RootDirectory and at least one of Networks and/or VirtualMachines
    $plifyConfig = ConvertFrom-Yaml -Yaml $RawYaml
    if ($plifyConfig.Keys.Count -gt 0 -and $plifyConfig.Keys -Contains "rootdirectory" -and ($plifyConfig.Keys -Contains "networks" -or $plifyConfig.Keys -Contains "virtualmachines") ) {
        return $plifyConfig
    }
}

function Get-PlifyConfigDir() {
    param (
        [Parameter(Mandatory=$false, Position=0)] [string] $Scope = "local"
    )

    if ($Scope -eq "global") {
        $sep = [system.io.Path]::DirectorySeparatorChar
        $localAppData = (Get-Item $env:LOCALAPPDATA).FullName
        return "$localAppData$($sep)Plify"
    } else {
        return (Get-Location).Path
    }
}

function Initialize-PlifyConfig() {
    param (
        [Parameter(Mandatory=$false, Position=0)] [string] $Scope = "local"
    )
    $PlifyConfigDir = Get-PlifyConfigDir $Scope
    if ( -not (Test-Path -Path $PlifyConfigDir) ) {
        Write-Debug "Initializing Plify config dir in $PlifyConfigDir"
        New-Item -Path $PlifyConfigDir -ItemType "directory"
    }
}

Export-ModuleMember -Function Get-PlifyConfigFromYaml,Initialize-PlifyConfig,Get-PlifyConfigDir