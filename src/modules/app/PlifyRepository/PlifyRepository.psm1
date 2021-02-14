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

function New-PlifyRepository() {
    param(
        [Parameter(Mandatory=$true)] [string] $Name,
        [Parameter(Mandatory=$false)] [bool] $Enabled = $false,
        [Parameter(Mandatory=$false)] [string] $Description = "",
        [Parameter(Mandatory=$false)] [string] $URL = ""
    )

    $repos = PlifyConfiguration\Get-PlifyConfiguration -Scope "Global" -RootElement "Repositories"
    if ( -not ($repos.Repositories.Keys -contains $Name)) {
        $repos.Repositories[$Name] = @{
            enabled = $Enabled
            description = $Description
            url = $URL
        }

        PlifyConfiguration\Set-PlifyGlobalConfig -Config $repos -RootElement "Repositories"

        Write-Output "Added New Plify Repository: $Name"
    }
}