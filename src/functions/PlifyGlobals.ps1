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
    "repolist" = @{Module="PlifyRepository"; Action="Get-PlifyRepository";Description="Lists plify repositories";Equivalent="plify repo list"}
    "r.l" = @{Module="PlifyRepository"; Action="Get-PlifyRepository";Description="Lists plify repositories";Equivalent="plify repo list"}
    "repo.newcert" = @{Module="PlifyRepository"; Action="New-PlifyRepositoryCertificate";Description="Creates a new repository certificate";Equivalent="N/A"}
}