function Get-PlifyHelp() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)] [string] $Module,
        [Parameter(Mandatory=$false)] [string] $Action = "default"
    )
  
    if ( [string]::IsNullOrWhiteSpace($Module) ) {
        $Module = "PlifyHelp"
    }

    Write-Debug "Help Module Requested: $Module"
    Write-Debug "Help Action Requested: $Action"

    # Always display basic help first
    Get-PlifyHelpText -Module "PlifyHelp" -Action "default"

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

    Write-Debug "Action Help File: $ActionHelpFileName"
    Write-Debug "Module Help File: $ModuleHelpFileName"

    # try the Action help file first, then the Module help file if the action one isn't found
    foreach ($dir in (Get-ChildItem -Path $ModuleRoot -Directory)) {
        $helpFiles = @(
            "$($dir.FullName)$($ds)$ModuleHelpFileName",
            "$($dir.FullName)$($ds)$ActionHelpFileName"
        )

        foreach ($file in $helpFiles) {
            Write-Debug "Trying Help file: $file"
            if (Test-Path -Path "$file") {
                Write-Debug "Loading Help File: $file"
                Write-PlifyConsoleHelpText -FilePath "$file"
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
        if ($line.Contains("__MODULEALIASES__")){
            $aliasesHelp = @{
                Headers = ("Module","Alias")
                Rows = @()
            }
            foreach ($folder in Get-ChildItem -Path ( (Get-Item $PSScriptRoot).Parent.Parent.FullName + "$($ds)app") ) {
                $moduleName = $folder.BaseName.Replace("Plify","")
                $aliases = $PlifyModuleAliases[$moduleName]
                #$helpTxt += "    $moduleName : $($aliases -join ',')`n"
                $aliasesHelp.Rows += , ($moduleName, ($aliases -join ','))
            }
            $helpTxt = Write-PlifyConsole -TableData $aliasesHelp -ReturnText $true -LeftPadding 4
            $line = $line.Replace("__MODULEALIASES__", $helpTxt)
        }
        if ($line.Contains("__PLIFYSHORTCUTS__")) {
            $shortcutHelp = @{
                Headers = @("Shortcut","Equivalent Cmd","Description")
                Rows = @()
            }
            foreach ($shortcut in $PlifyShortcuts.keys) {
                $targetShortcut = $shortcut
                if ($null -ne $PlifyShortcuts.$shortcut.Alias) {
                       $targetShortcut = $PlifyShortcuts.$shortcut.Alias
                }
                $shortcutHelp.Rows += , ($shortcut, $PlifyShortcuts.$targetShortcut.Equivalent, $PlifyShortcuts.$targetShortcut.Description)
            }
            $helpTxt = Write-PlifyConsole -TableData $shortcutHelp -ReturnText $true -LeftPadding 4
            $line = $line.Replace("__PLIFYSHORTCUTS__", $helpTxt)
        }
        if ($line.Contains("__MODULESHORTCUTS__")) {
            $moduleLine = $line.Split(":")
            if ($moduleLine.Count -eq 2) {
                $shortcutHelp = @{
                    Headers = @("Shortcut","Equivalent Cmd","Description")
                    Rows = @()
                }
                $module = $moduleLine[1]
                foreach ($shortcut in $PlifyShortcuts.Keys) {
                    $targetShortcut = $shortcut
                    if ($null -ne $PlifyShortcuts.$shortcut.Alias) {
                        $targetShortcut = $PlifyShortcuts.$shortcut.Alias
                    }
                    if ($PlifyShortcuts.$targetShortcut.Module -eq $module) {
                        $shortcutHelp.Rows += , ($shortcut, $PlifyShortcuts.$targetShortcut.Equivalent, $PlifyShortcuts.$targetShortcut.Description)
                    }
                }
                $helpTxt = Write-PlifyConsole -TableData $shortcutHelp -ReturnText $true -LeftPadding 4
                $line = $line.Replace("__MODULESHORTCUTS__:$module", $helpTxt)
            }
        }
        if ($line.Contains("__REMOVEALIASES__")) {
            $line = $line.Replace("__REMOVEALIASES__", ( $PlifyActionMapping["Remove"] -Join "," ) )
        }
        if ($line.Contains("__GETALIASES__")) {
            $line = $line.Replace("__GETALIASES__", ( $PlifyActionMapping["Get"] -Join "," ) )
        }
        if ($line.Contains("__NEWALIASES__")) {
            $line = $line.Replace("__NEWALIASES__",( $PlifyActionMapping["New"] -Join "," ) )
        }
        if ($line.Contains("__INITIALIZEALIASES__")) {
            $line = $line.Replace("__INITIALIZEALIASES__",( $PlifyActionMapping["Initialize"] -Join "," ) )
        }
        if ($line.Contains("__UPDATEALIASES__")) {
            $line = $line.Replace("__UPDATEALIASES__",( $PlifyActionMapping["Update"] -Join "," ) )
        }
        if ($line.Contains("__SYNCALIASES__")) {
            $line = $line.Replace("__SYNCALIASES__",( $PlifyActionMapping["Sync"] -Join "," ) )
        }

        [Console]::ForegroundColor = $lineColor
        Write-Output  "$line"
        [Console]::ForegroundColor = $OriginalForegroundColor
    }
}

Export-ModuleMember -Function Get-PlifyHelp