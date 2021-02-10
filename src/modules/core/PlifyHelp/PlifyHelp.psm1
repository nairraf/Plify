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

    # find and print the available App Modules that are installed
    foreach ($folder in Get-ChildItem -Path ( (Get-Item $PSScriptRoot).Parent.Parent.FullName + "$($ds)app") ) {
        $moduleName = $folder.BaseName.Replace("Plify","")
        Write-Output "      $moduleName"
    }

    # Get the appropriate .help file for the requested mnodule/action and display it.
    if ($Module -ne "PlifyHelp") {
       Get-PlifyHelpText -Module $Module -Action $Action
    }

    Write-Output ""
}

function Get-PlifyHelpText() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $Module,
        [Parameter(Mandatory=$true)] [string] $Action
    )

    $ModuleRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName

    # figure out the current locale
    $translation = Get-PlifyTranslation

    $ActionHelpFileName = "$Module$($ds)$Action.$($translation).help"
    $ModuleHelpFileName = "$Module$($ds)$Module.$($translation).help"
    
    if ($Action.ToLower() -eq "default") {
        $ActionHelpFileName = $ModuleHelpFileName
    }

    Write-Debug "Action Help File: $ActionHelpFileName"
    Write-Debug "Module Help File: $ModuleHelpFileName"

    # try the Action help file first, then the Module help file if the action one isn't found
    foreach ($dir in (Get-ChildItem -Path $ModuleRoot -Directory)) {
        $helpFiles = @(
            "$($dir.FullName)$($ds)$ActionHelpFileName",
            "$($dir.FullName)$($ds)$ModuleHelpFileName"
        )

        foreach ($file in $helpFiles) {
            Write-Debug "Trying Help file: $file"
            if (Test-Path -Path "$file") {
                Write-Debug "Loading Help File: $file"
                Write-PlifyConsoleHelpText -FilePath "$file"
                return
            }
        }
    }
}

function Write-PlifyConsoleHelpText() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $FilePath
    )
    $OriginalForegroundColor = [Console]::ForegroundColor

    foreach ($line in Get-Content -Path "$FilePath") {
        $lineColor = $OriginalForegroundColor
        if ($line.StartsWith('####')) {
            $line = $line.Replace('#','').Trim()
            $lineColor = "Magenta"
        }
        if ($line.StartsWith('###')) {
            $line = $line.Replace('#','').Trim()
            $lineColor = "Cyan"
        }
        if ($line.StartsWith('##')) {
            $line = $line.Replace('#','').Trim()
            $lineColor = "DarkBlue"
        }
        if ($line.StartsWith('#')) {
            $line = $line.Replace('#','').Trim()
            $lineColor = "Green"
        }

        [Console]::ForegroundColor = $lineColor
        Write-Output  "$line"
        [Console]::ForegroundColor = $OriginalForegroundColor
    }
}

Export-ModuleMember -Function Get-PlifyHelp