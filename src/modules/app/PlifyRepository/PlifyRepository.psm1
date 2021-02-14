# import all our external module functions into the modules current scope on module load
foreach ($file in (Get-ChildItem -Path "$PSScriptRoot$($ds)*.ps1" -Recurse)) {  
    . $file.FullName
}

##
function Get-PlifyRepository() {
    $repos = PlifyConfiguration\Get-PlifyConfiguration -Scope "Global" -RootElement "Repositories"

    $Repositories = @()

    foreach ($repo in ($repos.Repositories.Keys | Sort-Object)) {
        $Repositories += [PSCustomObject]@{
            PSTypeName = "Plify.Repository"
            Name = $repo
            Enabled = $repos.Repositories.$repo.enabled
            Description = $repos.Repositories.$repo.name
            URL = $repos.Repositories.$repo.url
        }
    }

    return $Repositories
}