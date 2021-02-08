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

function Initialize-PlifyConfig() {
    $sep = [system.io.Path]::DirectorySeparatorChar
    $PlifyConfigDir = "$($env:LOCALAPPDATA)$($sep)Plify"
    if ( -not (Test-Path -Path $PlifyConfigDir) ) {
        Write-Debug "Initializing Plify global config dir in appdata\local"
        New-Item -Path $PlifyConfigDir -ItemType "directory"
    }
}

Export-ModuleMember -Function Get-PlifyConfigFromYaml,Initialize-PlifyConfig