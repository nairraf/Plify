# Global Plify Variables
$Global:plifyDevRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
$Global:plifyRoot = (Get-Item $PSScriptRoot).Parent.FullName
$Global:plifyModuleRoot = "$plifyRoot$($ds)modules"

$Global:PlifyModuleAliases = @{
    "Configuration" = @("config", "conf")
    "Repository"     = @("repo")
}

$Global:PlifyActionMapping = @{
    "Get" = @("list","show","ls","get")
    "New" = @("new","add","create")
    "Initialize" = @("init","initialize")
    "Remove" = @("delete","del","remove","rm")
    "Update" = @("update","modify","mod","upd")
    "Sync" = @("sync","synchronize","pull")
}

$Global:PlifyShortcuts = @{
    "rl" = @{
        Module="PlifyRepository"
        Action="Get-PlifyRepository"
        Description="Lists plify repositories"
        Equivalent="plify repo list" 
    }
    "newRepoCert" = @{
        Module="PlifyRepository"
        Action="New-PlifyRepositoryCertificate"
        Description="Creates a new repository signing certificate"
        Equivalent="None. Shortcut Only" 
    }
    "globalConfig" = @{
        Module="PlifyConfiguration"
        Action="Get-PlifyConfiguration"
        Description="Displays Global Plify Configuration"
        Equivalent="plify config get @{Scope='Global'}"
        ActionParams=@{Scope="Global"}
    }
    "gc" = @{
        Alias="globalConfig"
    }
}