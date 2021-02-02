function Get-PlifyHelp() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)] [string] $Module,
        [Parameter(Mandatory=$false)] [string] $ModuleMessage,
        [Parameter(Mandatory=$false)] [switch] $Help
    )
    Write-Debug "-Help is: $Help"
    Write-Output ""
    Write-Output "Usage:"
    Write-Output "    plify [module] [action] [action_parameters]"
    Write-Output ""
    Write-Output "Available Modules:"
    Write-Output "    "


    if ( -not [string]::IsNullOrEmpty($Module) -and -not [string]::IsNullOrEmpty($ModuleMessage) ) {
        Write-Output ""
        Write-Output "Help for Module: $Module"
        Write-Output $ModuleMessage
    }
}

function Get-PlifyHelpHelp() {
    Get-PlifyHelp
}

Export-ModuleMember -Function Get-PlifyHelp,Get-PlifyHelpHelp