function Get-PlifyVerb([string]$Action) {
    foreach ($key in $PlifyActionMapping.Keys) {
        if ($PlifyActionMapping[$key].Contains($Action.ToLower())) {
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

    foreach ($key in $PlifyModuleAliases.Keys) {
        if ($PlifyModuleAliases[$key].Contains($ModuleName)) {
            $ModuleName = $key
        }
    }

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