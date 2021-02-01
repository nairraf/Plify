function Get-PlifyHelp() {
    param (
        [Parameter(Mandatory=$false)] [string] $Module,
        [Parameter(Mandatory=$false)] [string] $ModuleMessage
    )
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "    plify [module] [action] [action_parameters]"
    Write-Host ""
    Write-Host "Available Modules:"
    Write-Host "    "


    if ( -not [string]::IsNullOrEmpty($Module) -and -not [string]::IsNullOrEmpty($ModuleMessage) ) {
        Write-Host ""
        Write-Host "Help for Module: $Module"
        Write-Host $ModuleMessage
    }
}

function Get-PlifyHelpHelp() {
    Get-PlifyHelp
}

Export-ModuleMember -Function Get-PlifyHelp,Get-PlifyHelpHelp