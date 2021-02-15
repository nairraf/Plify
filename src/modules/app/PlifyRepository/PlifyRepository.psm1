# import all our external module functions into the modules current scope on module load
foreach ($file in (Get-ChildItem -Path "$PSScriptRoot$($ds)*.ps1" -Recurse)) {  
    . $file.FullName
}

##
function Get-PlifyRepository() {
    param (
        [Parameter(Mandatory=$false)] [string] $Name = ""
    )

    $repos = PlifyConfiguration\Get-PlifyConfiguration -Scope "Global" -RootElement "Repositories"

    if ( -not ([string]::IsNullOrEmpty($Name))) {
        if ($repos.Repositories.Keys -like $Name) {
            $newRepos = @{ Repositories = @{} }
            foreach ($repo in $repos.Repositories.Keys) {
                if ($repo -like $Name) {
                    $newRepos.Repositories[$repo] = $repos.Repositories[$repo]
                }
            }
        }
        $repos = $newRepos
    } 


    $Repositories = @()

    foreach ($repo in ($repos.Repositories.Keys | Sort-Object)) {
        $Repositories += [PSCustomObject]@{
            PSTypeName = "Plify.Repository"
            Name = $repo
            Enabled = $repos.Repositories.$repo.enabled
            Description = $repos.Repositories.$repo.description
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

function Remove-PlifyRepository() {
    param(
        [Parameter(Mandatory=$true)] [string] $Name
    )

    $repos = PlifyConfiguration\Get-PlifyConfiguration -Scope "Global" -RootElement "Repositories"
    if ($repos.Repositories.Keys -like $Name) {
        # we can't modify the hashtable we are looping (like calling Remove() )
        # so build a new hastable, and copy over the items that shouldn't be deleted
        # then save using the new hashtable
        $newRepos = @{ Repositories = @{} }
        foreach ($repo in $repos.Repositories.Keys) {
            if ( -not ($repo -like $Name)) {
                $newRepos.Repositories[$repo] = $repos.Repositories[$repo]
            }
        }

        PlifyConfiguration\Set-PlifyGlobalConfig -Config $newRepos -RootElement "Repositories"

        Write-Output "Removed Plify Repository: $Name"
    }
}

function Update-PlifyRepository() {
    param (
        [Parameter(Mandatory=$true)] [string] $Name,
        [Parameter(Mandatory=$false)] [string] $Enabled = $null,
        [Parameter(Mandatory=$false)] [string] $NewName = $null,
        [Parameter(Mandatory=$false)] [string] $Description = $null,
        [Parameter(Mandatory=$false)] [string] $URL = $null
    )

    $repos = PlifyConfiguration\Get-PlifyConfiguration -Scope "Global" -RootElement "Repositories"
    if ($repos.Repositories.Keys -like $Name) {
        $updated = $false
        # we use a string for Enabled as we need to test if it's set or not
        # bool not set will always = false so we can't be sure if that was requested or just the default
        if ([string]::IsNullOrEmpty($Enabled) -eq $false) {
            if ($Enabled.tolower().StartsWith("t") -or $Enabled.StartsWith("1")) {
                $repos.Repositories[$Name].Enabled = $true
            }
            if ($Enabled.tolower().StartsWith("f") -or $Enabled.StartsWith("0")) {
                $repos.Repositories[$Name].Enabled = $false
            }
            $updated = $true
        }
        if ([string]::IsNullOrEmpty($Description) -eq $false) {
            $repos.Repositories[$Name].Description = $Description
            $updated = $true
        }
        if ([string]::IsNullOrEmpty($URL) -eq $false) {
            $repos.Repositories[$Name].URL = $URL
            $updated = $true
        }
        if ([string]::IsNullOrEmpty($NewName) -eq $false) {
            $repos.Repositories[$NewName] = $repos.Repositories[$Name]
            $repos.Repositories.Remove($Name)
            $Name = $NewName
            $updated = $true
        }
        if ($updated) {
            PlifyConfiguration\Set-PlifyGlobalConfig -Config $repos -RootElement "Repositories"
            Write-Output ""
            Write-Output "Updated Repository: $Name"
            PlifyRepository\Get-PlifyRepository -Name $Name
        }
    }
}

function Sync-PlifyRepository() {
    # download the repository index and cache it locally
    # used when searching for images locally
}