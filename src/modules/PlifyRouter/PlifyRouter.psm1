function Get-PlifyVerb([string]$Action) {
    $ActionMapping = @{
        "Get" = @("list","show","ls","get")
        "New" = @("new","add","create")
    }

    foreach ($key in $ActionMapping.Keys) {
        if ($ActionMapping[$key].Contains($Action.ToLower())) {
            return $key
        }
    }
}

function Get-PlifyModule() {
    param (
        [Parameter(Mandatory=$true)] [string] $ModuleName
    )

    $Module = Get-Module -Name $ModuleName -ListAvailable

    if ($null -ne $Module) {
        return $Module
    }
}

function Get-PlifyModuleAction() {
    param (
        [Parameter(Mandatory=$true)] [PSModuleInfo] $Module,
        [Parameter(Mandatory=$true)] [string] $ActionName
    )
    
    foreach ($key in $Module.ExportedCommands.Keys) {
        if ($key.ToLower() -eq $ActionName.ToLower()) {
            return $Module.ExportedCommands[$key]
        }
    }
}

function Build-PlifyModuleName() {
    param (
        [Parameter(Mandatory=$true)] [string] $ModuleName
    )

    return "Plify$($ModuleName)"

}

function Build-PlifyActionName() {
    param (
        [Parameter(Mandatory=$true)] [PSModuleInfo] $Module,
        [Parameter(Mandatory=$true)] [string] $ActionName
    )

    return "$(Get-PlifyVerb($ActionName))-$($Module.Name)"
}

Export-ModuleMember -Function Get-PlifyVerb,Get-PlifyModule,Get-PlifyModuleAction,Build-PlifyModuleName,Build-PlifyActionName