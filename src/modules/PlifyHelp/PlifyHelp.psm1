function Get-PlifyHelp() {
    Write-Host "General Help mod 3"
}

function Get-PlifyHelpHelp() {
    Get-PlifyHelp
}

Export-ModuleMember -Function Get-PlifyHelp,Get-PlifyHelpHelp