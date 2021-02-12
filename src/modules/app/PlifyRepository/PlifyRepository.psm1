# import all our external module functions into the modules current scope on module load
foreach ($file in (Get-ChildItem -Path "$PSScriptRoot$($ds)*.ps1" -Recurse)) {  
    . $file.FullName
}

##
function Get-PlifyRepository() {
    $repos = PlifyConfiguration\Get-PlifyConfiguration -Scope "Global" -RootElement "Repositories"

    $TableData = @{
        Headers = @("Repository","Enabled","Description")
        Rows = @()
    }

    foreach ($repo in ($repos.Repositories.Keys | Sort-Object)) {
        $TableData.Rows += , ( $repo, $repos.Repositories.$repo.enabled, $repos.Repositories.$repo.name)
    }

    Write-PlifyConsole -TableData $TableData 
}