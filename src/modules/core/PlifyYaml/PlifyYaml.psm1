#Requires -Modules powershell-yaml

function Get-PlifyYamlConfig() {
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

Export-ModuleMember -Function Get-PlifyYamlConfig