# Global Plify Variables
$Global:plifyDevRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
$Global:plifyRoot = (Get-Item $PSScriptRoot).Parent.FullName
$Global:plifyModuleRoot = "$plifyRoot$($ds)modules"
$Global:plifyTypesRoot = "$plifyModuleRoot$($ds)types"

$Global:PlifyModuleAliases = @{
    "Configuration" = @("config", "conf")
    "Repository"     = @("repo")
}

$Global:PlifyActionMapping = @{
    "Show" = @("list","show","ls")
    "Get" = @("get")
    "New" = @("new","add","create")
    "Initialize" = @("init","initialize")
    "Remove" = @("delete","del","remove","rm")
    "Update" = @("update","modify","mod","upd")
    "Sync" = @("sync","synchronize","pull")
    "Build" = @("build", "generate","gen")
}

$Global:PlifyRoutes = @{
    ### Configuration Module Routes
    "gc" = @{Alias="globalConfig"}
    "globalConfig" = @{
        Module="PlifyConfiguration"
        Action="Show-PlifyConfiguration"
        Description="Displays Global Plify Configuration"
        Equivalent="plify config get @{Scope='Global'}"
        ActionParams=@{Scope="Global"}
    }
    ### Repository Module Routes
    "repository backupcert" = @{
        Module="PlifyRepository"
        Action="Backup-PlifyRepositoryCertificate"
        Description="Backup an existing repository signing certificate"
        Equivalent="None. Shortcut Only"
        Hide=$true
    }
    "repository build" = @{
        Module="PlifyRepository"
        Action="Build-PlifyRepositoryInventory"
        Description="Builds repository inventory file"
        Equivalent="None. Shortcut Only"
        Hide=$true
    }
    "rl" = @{
        Module="PlifyRepository"
        Action="Get-PlifyRepository"
        Description="Lists plify repositories"
        Equivalent="plify repo list" 
    }
    "repository newcert" = @{
        Module="PlifyRepository"
        Action="New-PlifyRepositoryCertificate"
        Description="Creates a new repository signing certificate"
        Equivalent="None. Shortcut Only"
        Hide=$true
    }
    "repository restorecert" = @{
        Module="PlifyRepository"
        Action="Restore-PlifyRepositoryCertificate"
        Description="Restore repository signing certificate"
        Equivalent="None. Shortcut Only"
        Hide=$true
    }
}