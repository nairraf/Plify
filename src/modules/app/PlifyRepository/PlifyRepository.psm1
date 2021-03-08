#Requires -Modules powershell-yaml
using module .\..\..\..\types\PlifyBase.types.psm1
using module .\..\..\..\types\PlifyRepository.types.psm1

# import all our external module functions into the modules current scope on module load
foreach ($file in (Get-ChildItem -Path "$PSScriptRoot$($ds)*.ps1" -Recurse)) {  
    . $file.FullName
}

<#
.SYNOPSIS
Returns the location of the bundled openssl.exe
#>
function Get-PlifyRepositoryOpenSSL() {
    return "$PSScriptRoot$($ds)bin$($ds)openssl$($ds)openssl.exe"
}

<#
.SYNOPSIS
Returns the location of the plify openssl configuratio file
#>
function Get-PlifyRepositoryOpenSSLConfig() {
    return "$PSScriptRoot$($ds)bin$($ds)openssl$($ds)openssl.cnf"
}

<#
.SYNOPSIS
Returns the plify global certificate directory to the caller
#>
function Get-PlifyRepositoryCertificateDir() {
    $configDir = PlifyConfiguration\Get-PlifyConfigurationDir -Scope "Global"
    $repoCertDir = "$configDir$($ds)certificates"
    if ( -not (Test-Path -Path $repoCertDir)) {
        New-Item -Path $repoCertDir -ItemType Directory | Out-Null
    }
    return $repoCertDir
}

<#
.SYNOPSIS
List all the repositories in the global configuration

.PARAMETER Name
By default all repositories are listed. you can filter
the results using the name parameter. Wildcards are supported
#>
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
        $r = [PlifyRepository]::new()
        $r.Name = $repo
        $r.Enabled = $repos.Repositories.$repo.enabled
        $r.Description = $repos.Repositories.$repo.description
        $r.URL = $repos.Repositories.$repo.url
        $r.Thumbprint = $repos.Repositories.$repo.thumbprint
        $Repositories += $r
    }

    return $Repositories
}

<#
.SYNOPSIS
Displays the list of repositories to the user

.DESCRIPTION
Adds ExitCode status to the repos and displays to the user

.PARAMETER Name
be default it will return all repositories.
Name can be used to return specific repositories
wildcard (*) is supported

.EXAMPLE
plify repo ls @{Name=*prod*}
    # lists all repositories with prod in their name

.NOTES
'plify repo ls' is mapped here
#>
function Show-PlifyRepository() {
    param (
        [Parameter(Mandatory=$false)] [string] $Name = ""
    )

    return Get-PlifyRepository -Name $Name
}

<#
.SYNOPSIS
Adds a new plify repository to the global configuration

.PARAMETER Name
The name of the new repository

.PARAMETER Enabled
Enable (true) or Disable (false) the new repository
Default is False

.PARAMETER Description
The description of the new repository

.PARAMETER URL
The URL for the new repository. This should be the URL 
of where the repositories inventory file is located 

.PARAMETER Thumbprint
Thumbprint of the repositories public certificate

.NOTES
'plify repo new' is mapped here
#>
function New-PlifyRepository() {
    param(
        [Parameter(Mandatory=$true)] [string] $Name,
        [Parameter(Mandatory=$false)] [bool] $Enabled = $false,
        [Parameter(Mandatory=$false)] [string] $Description = "",
        [Parameter(Mandatory=$false)] [string] $URL = "",
        [Parameter(Mandatory=$false)] [string] $Thumbprint = ""
    )

    $repos = PlifyConfiguration\Get-PlifyConfiguration -Scope "Global" -RootElement "Repositories"
    if ( -not ($repos.Repositories.Keys -contains $Name)) {
        $repos.Repositories[$Name] = @{
            enabled = $Enabled
            description = $Description
            url = $URL
            thumbprint = $Thumbprint
        }

        PlifyConfiguration\Set-PlifyGlobalConfig -Config $repos -RootElement "Repositories"

        return [PlifyReturn]::new(
            [PlifyStatus]::OK, 
            (Get-PlifyMessage -Module Repository -Message AddRepositorySuccess -Replacements @{Name=$Name}) )
    }
}

<#
.SYNOPSIS
Removes a plify repository from the global configuration

.PARAMETER Name
The name of the repository to remove

.NOTES
'plify repo remove' is mapped here
#>
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

        return [PlifyReturn]::new(
            [PlifyStatus]::OK, 
            (Get-PlifyMessage -Module Repository -Message RemoveRepositorySuccess -Replacements @{Name=$Name}) )
    }
}

<#
.SYNOPSIS
Updates Plify Repository Settings

.PARAMETER Name
The name of the plify repository to modify

.PARAMETER Enabled
Control if the repository is Enabled (true) or Disabled (False)
Disabled repositories do not have their inventory cached

.PARAMETER NewName
Renames a repository

.PARAMETER Description
The reposotiry description

.PARAMETER URL
The base URL of the repository. this should be the directory
where the repository inventory file is located

.PARAMETER Thumbprint
The Certificate Public Key's computed hash.
NOTE: New|Restore-PlifyRepositoryCertificate (or 'plify repo [new|restore]cert')
automatically set the repository thumbprint

.NOTES
'plify repo update' is mapped here
#>
function Update-PlifyRepository() {
    param (
        [Parameter(Mandatory=$true)] [string] $Name,
        [Parameter(Mandatory=$false)] [string] $Enabled = $null,
        [Parameter(Mandatory=$false)] [string] $NewName = $null,
        [Parameter(Mandatory=$false)] [string] $Description = $null,
        [Parameter(Mandatory=$false)] [string] $URL = $null,
        [Parameter(Mandatory=$false)] [string] $Thumbprint = $null
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
        if ([string]::IsNullOrEmpty($Thumbprint) -eq $false) {
            $repos.Repositories[$Name].Thumbprint = $Thumbprint
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
            $NextCall = [PlifyNextCall]::new(
                "PlifyRepository",
                "Get-PlifyRepository",
                @{Name=$Name}
            )
            return [PlifyReturn]::new(
                [PlifyStatus]::OK, 
                (Get-PlifyMessage -Module Repository -Message UpdatedRepo -Replacements @{Name=$Name}),
                $NextCall )
        }
    }
}

<#
.SYNOPSIS
Backups up a plify repository certificate

.DESCRIPTION
Exports a repository certificate to an encrypted PFX file
that van later be imported

.PARAMETER Name
The name of the repository holding the certificate that
should be backed up

.PARAMETER Path
The directory where the PFX file will be placed. The PFX
Backup file will be called <repo>.pfx.

.PARAMETER Password
The password for the PFX archive. This password will be needed
to open and/or restore the PFX archive at a later date

.PARAMETER Force
Overwrite a previously backed up PFX archive

.NOTES
'plify repo backupcert' is mapped here
#>
function Backup-PlifyRepositoryCertificate() {
    param(
        [Parameter(Mandatory=$true)] [string] $Name,
        [Parameter(Mandatory=$true)] [string] $Path,
        [Parameter(Mandatory=$true)] [string] $Password,
        [Parameter(Mandatory=$false)] [switch] $Force
    )
    $openssl = Get-PlifyRepositoryOpenSSL
    $certDir = Get-PlifyRepositoryCertificateDir
    $certBaseName = "$certDir$($ds)$Name"
    $backupFileName = "$Path$($ds)$Name.pfx"

    # make sure that we have a private key and a certificate for this repository
    if ( (Test-Path -Path "$certBaseName.key.private") -eq $false -and (Test-Path -Path "$certBaseName.crt") -eq $false ) {
        return [PlifyReturn]::new(
            [PlifyStatus]::ERROR, 
            (Get-PlifyMessage -Module Repository -Message ErrorCertFilesNotFound -Replacements @{Name=$Name}) )
    }
    
    # we do not overwrite backup files unless forced
    if ( (Test-Path -Path $backupFileName) -eq $true -and $Force -eq $false ) {
        return [PlifyReturn]::new(
            [PlifyStatus]::ERROR, 
            (Get-PlifyMessage -Module Repository -Message BackupFileExists -Replacements @{FILEPATH=$backupFileName}) )
    }

    & $openssl pkcs12 -export -out $backupFileName -inkey "$certBaseName.key.private" -in "$certBaseName.crt" -passout pass:$Password 2>&1 | Out-Null
    if ( ($LASTEXITCODE -gt 0) -or (Test-Path -Path $backupFileName) -eq $false ){
        return [PlifyReturn]::new(
            [PlifyStatus]::ERROR, 
            (Get-PlifyMessage -Module Repository -Message BackupFailed -Replacements @{FILEPATH=$backupFileName}) )
    }

    return [PlifyReturn]::new(
            [PlifyStatus]::OK, 
            (Get-PlifyMessage -Module Repository -Message BackupSuccess -Replacements @{FILEPATH=$backupFileName}) )
}

<#
.SYNOPSIS
Extracts the public key from the public certificate

.DESCRIPTION
Long description

.PARAMETER Name
The name of the repository that the extracted key is for

.EXAMPLE
try {
    Set-PlifyRepositoryPublicKey -Name SomeRepoName
} catch {
    // do something
}

.NOTES
A try catch should be used when calling Set-PlifyRepositoryPublicKey
#>
function Set-PlifyRepositoryPublicKey() {
    param(
        [Parameter(Mandatory=$true)] [string] $Name
    )
    $openssl = Get-PlifyRepositoryOpenSSL
    $certDir = Get-PlifyRepositoryCertificateDir
    $certBaseName = "$certDir$($ds)$Name"

    # extract the public key from the public cert
    & $openssl x509 -in "$certBaseName.crt" -pubkey -noout > "$certBaseName.key.public" 2>&1 | Out-Null
    if ($LASTEXITCODE -gt 0) {
        throw
    }

    Update-PlifyRepository -Name $Name -Thumbprint (Get-FileHash -Path "$certBaseName.key.public" -Algorithm SHA256).Hash | Out-Null
}

<#
.SYNOPSIS
Restores a previously backed up certificate for a plify repository

.PARAMETER Name
The name of the repository to restore the certificate for

.PARAMETER Path
the full path to the .PFX file that was previously backer up

.PARAMETER Password
The password to decrypt the PFX archive. This was set previously
when backing up the certificate. See "Backup-PlifyRepositoryCertificate" 

.PARAMETER Force
use Force to overwrite the existing certificate for the given plify repository

.NOTES
'plify repo backupcert' is mapped here
#>
function Restore-PlifyRepositoryCertificate() {
    param(
        [Parameter(Mandatory=$true)] [string] $Name,
        [Parameter(Mandatory=$true)] [string] $Path,
        [Parameter(Mandatory=$true)] [string] $Password,
        [Parameter(Mandatory=$false)] [switch] $Force
    )
    $openssl = Get-PlifyRepositoryOpenSSL
    $certDir = Get-PlifyRepositoryCertificateDir
    $certBaseName = "$certDir$($ds)$Name"

    if ( (Test-Path -Path $Path) -eq $False -or ($Path.EndsWith("pfx")) -eq $false) {
        return [PlifyReturn]::new(
            [PlifyStatus]::ERROR, 
            (Get-PlifyMessage -Module Repository -Message InvalidPFXPath) )
    }

    # make sure we don't restore a certifacte over an existing one unless forced
    if ( (Test-Path -Path "$certBaseName.key.private") -eq $true -and $Force -eq $false) {
        return [PlifyReturn]::new(
            [PlifyStatus]::ERROR, 
            (Get-PlifyMessage -Module Repository -Message PFXExists) )
    }

    & $openssl pkcs12 -in $Path -nocerts -nodes -passin pass:$Password | & $openssl pkcs8 -nocrypt -out "$certBaseName.key.private" 2>&1 | Out-Null
    if ($LASTEXITCODE -gt 0) {
        return [PlifyReturn]::new(
            [PlifyStatus]::ERROR, 
            (Get-PlifyMessage -Module Repository -Message ErrorRestorePrivateKey -Replacements @{Path=$Path}) )
    }

    & $openssl pkcs12 -in $Path -nokeys -clcerts -passin pass:$Password | & $openssl x509 -out "$certBaseName.crt" 2>&1 | Out-Null
    if ($LASTEXITCODE -gt 0) {
        return [PlifyReturn]::new(
            [PlifyStatus]::ERROR, 
            (Get-PlifyMessage -Module Repository -Message ErrorRestoreCertificate -Replacements @{Path=$Path}) )
    }

    & $openssl x509 -in "$certBaseName.crt" -pubkey -noout > "$certBaseName.key.public" | Out-Null
    if ($LASTEXITCODE -gt 0) {
        return [PlifyReturn]::new(
            [PlifyStatus]::ERROR, 
            (Get-PlifyMessage -Module Repository -Message ErrorRestorePublicKey -Replacements @{Path=$Path}) )
    }

    try {
        Set-PlifyRepositoryPublicKey -Name $Name
    } catch {
        return [PlifyReturn]::new(
            [PlifyStatus]::ERROR, 
            (Get-PlifyMessage -Module Repository -Message ErrorExtractPublicKey -Replacements @{REPO=$Name}) )
    }

    return [PlifyReturn]::new(
        [PlifyStatus]::OK, 
        (Get-PlifyMessage -Module Repository -Message RestoredCertificate -Replacements @{Path=$Path;Name=$Name}) )
}

<#
.SYNOPSIS
returns the location of the global plify repository cache file
#>
function Get-PlifyRepositoryCacheFile() {
    return "$(PlifyConfiguration\Get-PlifyConfigurationDir -Scope 'Global')$($ds)repositorycache.json"
}

<#
.SYNOPSIS
Syncrhonizes the plify repository cache

.DESCRIPTION
Downloads latest inventory files from all enabled repositories
and updates the local repository cache

.PARAMETER Force
By default plify will only update the repository cache only
once per day. Use Force to override and force the update

.NOTES
'plify repo sync' is mapped here
#>
function Sync-PlifyRepository() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)] [switch] $Force
    )

    # by default we only run once per 24 hour window
    $cacheFile = Get-PlifyRepositoryCacheFile
    if ( (Test-Path -Path $cacheFile) -and $Force -eq $false) {
        $lastUpdate = (Get-Item -Path $cacheFile).LastWriteTimeUtc
        $currentTime = Get-Date -AsUTC
        if ($lastUpdate -gt $currentTime.AddDays(-1)) {
            return [PlifyReturn]::new(
                [PlifyStatus]::WARNING, 
                (Get-PlifyMessage -Module Repository -Message SyncAlreadyRan) )
        }
    }

    $EnabledRepos = Get-PlifyRepository | Where-Object { $_.Enabled -eq $true }

    $cache = @{}
    $start = Get-Date
    $r = 0
    foreach ($repo in $EnabledRepos) {
        Write-Progress -Activity "Syncrhonizing Plify Repositories" -Status "Processing $($r+1) of $($EnabledRepos.Count)" -PercentComplete (($r)/$EnabledRepos.Count*100) -CurrentOperation "Downloading Inventory: $($repo.Name)"
        
        $cache[$repo.Name] = @{}
        $indexContent = PlifyWeb\Get-PlifyWebContent -Url "$($repo.URL)/inventory.json"
        Write-Progress -Activity "Syncrhonizing Plify Repositories" -Status "Processing $($r+1) of $($EnabledRepos.Count)" -PercentComplete (($r)/$EnabledRepos.Count*100) -CurrentOperation "Updating Inventory: $($repo.Name)"
        if ( -not ([string]::IsNullOrEmpty($indexContent))) {
            $index = ($indexContent | ConvertFrom-Json -Depth 5)
            $p = 0
            $numImages = ($index | Get-Member -MemberType NoteProperty).Count
            foreach ($package in $index | Get-Member -MemberType NoteProperty){
                # it's no use having a second write-progress as even a large repo with thousands of entries is processed very quickly
                # and you just see a "flash" before it completes. you would have to really slow it down with start-sleep to see the progress
                # and that just doesn't make sense.
                Write-Progress -Activity "Processing Inventory" -Id 1 -PercentComplete (($p+1)/$numImages*100) -Status "$($repo.Name) "

                $cache[$repo.Name][$package.Name] = $index.($package.Name)

                $p += 1
            }
        }
        Write-Progress -Activity "Processing Inventory" -Id 1 -Status "$($repo.Name)" -PercentComplete 100 -Completed
        $r += 1
    }
    Write-Progress -Activity "Syncrhonizing Plify Repositories" -Status "Completed" -PercentComplete 100 -Completed
    $cache | ConvertTo-Json -Depth 5 -Compress | Out-File -FilePath $cacheFile
    $end = Get-Date
   
    return [PlifyRepoSync]::new(
        [PlifyStatus]::OK,
        (Get-PlifyMessage -Module Repository -Message SyncSuccess -Replacements @{Repos="$($EnabledRepos.Name -join ", ")"}),
        (($end - $start).TotalSeconds.ToString("#.###"))
    )
}

<#
.SYNOPSIS
Creates a new Plify Repository Certificate

.DESCRIPTION
Plify Signing Certificates are used to sign and validate
plify repository inventory files. This creates a new
signing certificate for a plify repository.

.PARAMETER Name
The name of the new repository

.PARAMETER Days
the number of days the certificate is valid for
default is 10 years

.PARAMETER KeySize
The RSA keysize. Default is 4096

.PARAMETER Force
Use force to overwrite an existing certificate

.NOTES
'Plify repo newcert' is mapped here
#>
function New-PlifyRepositoryCertificate() {
    param(
        [Parameter(Mandatory=$true)] [string] $Name,
        [Parameter(Mandatory=$false)] [string] $Days = 3650, 
        [Parameter(Mandatory=$false)] [int] $KeySize = 4096,
        [Parameter(Mandatory=$false)] [switch] $Force
    )

    # only generate certs for existing repositories
    if ( $null -eq (Get-PlifyRepository -Name $Name) ) {
        return [PlifyReturn]::new(
            [PlifyStatus]::WARNING, 
            (Get-PlifyMessage -Module Repository -Message RepositoryNotExists -Replacements @{Name=$Name}) )
    }

    $openssl = Get-PlifyRepositoryOpenSSL
    $config = Get-PlifyRepositoryOpenSSLConfig
    $certDir = Get-PlifyRepositoryCertificateDir
    $certBaseName = "$certDir$($ds)$Name"

    $subject = "/CN=$Name"

    # make sure we don't overwrite certs unless forced
    if ( (Test-Path -Path "$certBaseName.key.private") -eq $true -and $Force -eq $false ) {
        return [PlifyReturn]::new(
            [PlifyStatus]::WARNING, 
            (Get-PlifyMessage -Module Repository -Message NoOverwritingCertificates -Replacements @{Name=$Name}) )
    }

    # we never regenerate certificates for plify default repo's
    if ($Name -eq "PlifyProd" -or $Name -eq "PlifyDev") {
        return [PlifyReturn]::new(
            [PlifyStatus]::ERROR, 
            (Get-PlifyMessage -Module Repository -Message NoCertificateGenForDefaultRepos) )
    }

    # generate the new private key and public cert
    & $openssl req -x509 -newkey rsa:$KeySize -keyout "$certBaseName.key.private" -out "$certBaseName.crt" -days $Days -nodes -subj $subject -config $config 2>&1 | Out-Null
    if ($LASTEXITCODE -gt 0) {
        return [PlifyReturn]::new(
            [PlifyStatus]::ERROR, 
            (Get-PlifyMessage -Module Repository -Message CertificateGenFailed -Replacements @{CertName=$certBaseName}) )
    }

    try {
        Set-PlifyRepositoryPublicKey -Name $Name
    } catch {
        return [PlifyReturn]::new(
            [PlifyStatus]::ERROR, 
            (Get-PlifyMessage -Module Repository -Message ErrorExtractPublicKey -Replacements @{REPO=$Name}) )
    }

    return [PlifyReturn]::new(
        [PlifyStatus]::OK, 
        (Get-PlifyMessage -Module Repository -Message CertificateGenSuccess -Replacements @{Name=$Name}) )
}

<#
.SYNOPSIS
Builds the inventory for a plify repository

.DESCRIPTION
Creates and signs a plify repository inventory file
Requires the Repositories Private key

.PARAMETER Name
The name of the repository to build the inventory for

.NOTES
'plify repo build' is mapped here
#>
function Build-PlifyRepositoryInventory() {
    param(
        [Parameter(Mandatory=$true)] [string] $Name
    )

}