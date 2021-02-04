#Requires -Modules powershell-yaml

function Get-PlifyYamlConfig() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $RawYaml
    )

    return ConvertFrom-Yaml -Yaml $RawYaml

}

Export-ModuleMember -Function Get-PlifyYamlConfig