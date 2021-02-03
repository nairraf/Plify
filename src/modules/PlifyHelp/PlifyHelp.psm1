function Get-PlifyHelp() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)] [string] $Module,
        [Parameter(Mandatory=$false)] [string] $Action
    )
  
    if ( [string]::IsNullOrWhiteSpace($Module) ) {
        $Module = "PlifyHelp"
    }

    if ( [string]::IsNullOrWhiteSpace($Action) ) {
        $Action = "default"
    }

    Write-Debug "Help Module Requested: $Module"
    Write-Debug "Help Action Requested: $Action"

    # Always display basic help first
    Get-PlifyHelpText -Module "PlifyHelp" -Action "default"


    # find and print the available Modules that are installed
    foreach ($folder in Get-ChildItem -Path ((Get-Item $PSScriptRoot).Parent.FullName) ) {
        $moduleName = $folder.BaseName.Replace("Plify","")
        $bypassModules = @("help","utils","router")
        if (-not $bypassModules.Contains($moduleName.ToLower())) {
            Write-Output "      $moduleName"
        }
    }

    # Get the appropriate .help file for the requested mnodule/action and display it.
    if ($Module -ne "PlifyHelp") {
       Get-PlifyHelpText -Module $Module -Action $Action
    }
}

function Get-PlifyHelpText(){
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $Module,
        [Parameter(Mandatory=$true)] [string] $Action
    )

    $ModuleRoot = (Get-Item $PSScriptRoot).Parent.FullName

    $ActionHelpFileName = "$Module\$Action.help"
    $ModuleHelpFileName = "$Module\$Module.help"
    
    if ($Action.ToLower() -eq "default") {
        $ActionHelpFileName = $ModuleHelpFileName
    }

    Write-Debug "Action Help File: $ActionHelpFileName"
    Write-Debug "Module Help File: $ModuleHelpFileName"

    # try the action file first
    if (Test-Path -Path "$ModuleRoot\$ActionHelpFileName" ) {
        Write-Debug "Loading Help File: $ModuleRoot\$ActionHelpFileName"
        Write-PlifyConsoleHelpText -FilePath "$ModuleRoot\$ActionHelpFileName"
        return
    }

    # try the module file if the action file fails
    if (Test-Path -Path "$ModuleRoot\$ModuleHelpFileName" ) {
        Write-Debug "Loading Help File: $ModuleRoot\$ModuleHelpFileName"
        Write-PlifyConsoleHelpText -FilePath "$ModuleRoot\$ModuleHelpFileName"
        return
    }
}

function Write-PlifyConsoleHelpText() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $FilePath
    )
    $OriginalForegroundColor = [Console]::ForegroundColor

    foreach ($line in Get-Content -Path "$FilePath") {
        $lineColor = $false
        if ($line.StartsWith('#')) {
            $line = $line.Replace('#','').Trim()
            $lineColor = $true
        }

        if ($lineColor) { [Console]::ForegroundColor = "Green" }
        Write-Output  "$line"
        if ($lineColor) { [Console]::ForegroundColor = $OriginalForegroundColor }
    }
}

Export-ModuleMember -Function Get-PlifyHelp