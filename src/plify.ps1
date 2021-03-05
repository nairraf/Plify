[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, Position=0)] [string] $Module,
    [Parameter(Mandatory=$false, Position=1)] $Action, # we can't force a type here because of shortcuts. this could be string or hastable
    [Parameter(Mandatory=$false, Position=2)] [hashtable] $ActionParams = @{},
    [Parameter(Mandatory=$false)] [switch] $Help,
    [Parameter(Mandatory=$false)] [switch] $Flush
)

# bootstrap
# we set the globals in the bootstrap file so $ds (Directory Seperator Character global) can't ne used here as it doesn't exist yet
# we set them there so that the globals are also available in our tests. Tests execute the bootstrap as well.
# in all plify modules/fundtions/tests you can use $ds as the directory seperator character
$bootStrapScript = "$PSScriptRoot$([system.io.path]::DirectorySeparatorChar)functions$([system.io.path]::DirectorySeparatorChar)bootstrap.ps1"
. $bootStrapScript
Invoke-PlifyBootstrap

# we import modules on demand - no preloading
# so flush will import all modules, then remove them so that the ones that are re-loaded are fresh
if ($Flush) {
    Reset-Plify
}

# test if we have a verbose or debug flag and pass it on so modules can use them
$extraFlags = @{
    Verbose = if ($PSBoundParameters.Verbose -eq $true) {$true} else {$false};
    Debug = if ($PSBoundParameters.Debug -eq $true) {$true} else {$false};
}

# get friendly output for the $ActionParams dictionary
$ActionParamsString = Build-PlifyStringFromHash $ActionParams

# route requests via naming convention
if ( -not [string]::IsNullOrEmpty($Module) ) {
    # see if we have a shortcut registered:
    $plifyShortcut = $false
    # build our plify shortcut
    $shortcut = $Module
    if (-not [string]::IsNullOrEmpty($Action)) {
        if ($Action.GetType().Name -eq "Hashtable") {
            $ActionParams = $Action
            $Action = ""
        } else {
            $shortcut = "$Module $Action"
        }
    } 

    # plify shortcuts can overide/point to any module/action
    # we loop through all available shortcuts and see if we find a match
    # if we find a match we assign the module/action which will cause plify
    # bypass the Build-PlifyModuleName, and Build-PlifyActionName functions
    # which Plify uses to try and detect the correct module and actions
    if ($PlifyShortcuts.Keys -contains $shortcut) {
        if ($null -ne $PlifyShortcuts.$shortcut.Alias) {
            $shortcut = $PlifyShortcuts.$shortcut.Alias
        }
        $ModuleName = $PlifyShortcuts.$shortcut.Module
        $ActionName = $PlifyShortcuts.$shortcut.Action
        # if the shortcut specified actions, merge them in to the main
        # ActionParams hashtable
        if ($null -ne $PlifyShortcuts.$shortcut.ActionParams) {
            foreach ($Action in $PlifyShortcuts.$shortcut.ActionParams.Keys) {
                $ActionParams.$Action = $PlifyShortcuts.$shortcut.ActionParams.$Action
            }
        }
        Write-Debug "Plify Shorcut Detected, Redirecting to Module: $ModuleName, Action: $ActionName"
        $plifyShortcut = $true
    }

    if (-not $plifyShortcut) {
        $ModuleName = PlifyRouter\Build-PlifyModuleName -ModuleName $Module
    }

    # see if we can find a module of that name
    $ModuleFound = PlifyRouter\Get-PlifyModule -ModuleName $ModuleName

    if ($null -ne $ModuleFound) {
        Write-Debug "Found Module: $($ModuleFound.Name)"
        
        if ( -not [string]::IsNullOrEmpty($Action) -or $plifyShortcut -eq $true) {
            if (-not $plifyShortcut) {
                $ActionName = PlifyRouter\Build-PlifyActionName -Module $ModuleFound -ActionName $Action
            }
            Write-Debug "Detected Action Name: $ActionName"
            $ActionFound = PlifyRouter\Get-PlifyModuleAction -Module $ModuleFound -ActionName $ActionName
            if ($null -ne $ActionFound) {
                Write-Debug "Found Action: $($ActionFound.Name)"
            }
        }
    }
}

# see if we found a valid module/action, if not redirect to help
if ($null -eq $ModuleFound -or $null -eq $ActionFound) {
    $Help = $true
}

## see if help has been requested, if so display help and exit
if ($Help) {
    if ( $null -ne $ModuleFound -and $null -eq $ActionFound) {
        Write-Debug "Getting Help for Module: $($ModuleFound.Name)"
        PlifyHelp\Get-PlifyHelp -Module $ModuleFound.Name @extraFlags
        Exit
    } 
    
    if ($null -ne $ModuleFound -and $null -ne $ActionFound) {
        Write-Debug "Getting Help for Module\Action: $($ModuleFound.Name)\$($ActionFound.Name)"
        PlifyHelp\Get-PlifyHelp -Module $ModuleFound.Name -Action $ActionFound.Name @extraFlags
        Exit
    }

    PlifyHelp\Get-PlifyHelp @extraFlags
    Exit
}

# call the requested module, action and pass on action parameters
try {
    if ($ActionParams.Count -gt 0) {
        Write-Debug "Executing: $($ModuleFound.Name)\$($ActionFound.Name) $ActionParamsString"
        $ret = & $ModuleFound\$ActionFound @ActionParams @extraFlags
    } else {
        Write-Debug "Executing: $($ModuleFound.Name)\$($ActionFound.Name)"
        $ret = & $ModuleFound\$ActionFound @extraFlags
    }
    
    # see if $ret is a list or a single entity and get the nextcall value
    if ($ret.Count -gt 1) {
        # $ret is a list - use the first element's next call
        $nextCall = $ret[0].NextCall
    } else {
        # ret is not an array, see if it has a next call
        $nextCall = $ret.NextCall
    }
    
    # if we don't have a next call, then just output $ret
    # otherwise we display ret and call the next call
    if ( $null -eq $nextCall ) {
        $ret
    } else {
        Write-Output ""
        Write-Output "$($ret.Status) - $($ret.Message)"

        # if the last call passed and we have a next module and action
        # see if we can find the module/action then call it
        # we loop until there is no next call or we encounter an error
        while ( [string]::IsNullOrEmpty($ret.NextCall.Module) -eq $false -and 
                [string]::IsNullOrEmpty($ret.NextCall.Action) -eq $false -and 
                $ret.ExitCode -eq 0) {
            $ModuleFound = PlifyRouter\Get-PlifyModule -ModuleName ($ret.NextCall.Module)
            $ActionFound = PlifyRouter\Get-PlifyModuleAction -Module $ModuleFound -ActionName ($ret.NextCall.Action)
            [hashtable] $parms = $ret.NextCall.ActionParams
            if ([string]::IsNullOrEmpty($ModuleFound) -eq $false -and [string]::IsNullOrEmpty($ActionFound) -eq $false){
                $ret = & $ModuleFound\$ActionFound @parms @extraFlags
                $ret
            }
        }
    }

    if ($ret.ExitCode -gt 0) {
        if ($error.count -gt 0) {
            Write-PlifyErrors
        }
    }

    exit $ret.ExitCode
} catch {
    Write-PlifyErrors
    exit 100
}