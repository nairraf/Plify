#Requires -Modules powershell-yaml

# import all our external module functions into the modules current scope on module load
foreach ($file in (Get-ChildItem -Path "$PSScriptRoot$($ds)*.ps1" -Recurse)) {  
    . $file.FullName
}

function Get-PlifyRepositoryOpenSSL() {
    return "$PSScriptRoot$($ds)bin$($ds)openssl$($ds)openssl.exe"
}

function Get-PlifyRepositoryOpenSSLConfig() {
    return "$PSScriptRoot$($ds)bin$($ds)openssl$($ds)openssl.cnf"
}

function Get-PlifyRepositoryCertificateDir() {
    $configDir = PlifyConfiguration\Get-PlifyConfigurationDir -Scope "Global"
    $repoCertDir = "$configDir$($ds)certificates"
    if ( -not (Test-Path -Path $repoCertDir)) {
        New-Item -Path $repoCertDir -ItemType Directory | Out-Null
    }
    return $repoCertDir
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
            Thumbprint = $repos.Repositories.$repo.thumbprint
        }
    }

    return $Repositories
}

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
            Write-Output ""
            Write-Output "Updated Repository: $Name"
            PlifyRepository\Get-PlifyRepository -Name $Name
        }
    }
}

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
        throw "Certificate files not found for repository: $Name"
    }
    
    # we do not overwrite backup files unless forced
    if ( (Test-Path -Path $backupFileName) -eq $true -and $Force -eq $false ) {
        Throw "BackupFile: $backupFileName already exists...skipping"
    }

    & $openssl pkcs12 -export -out $backupFileName -inkey "$certBaseName.key.private" -in "$certBaseName.crt" -passout pass:$Password 2>&1 | Out-Null
    if ( ($LASTEXITCODE -gt 0) -or (Test-Path -Path $backupFileName) -eq $false ){
        throw "Failed backingup certificate to $backupFileName"
    }

    Write-Output ""
    Write-Output "BackupFile: $backupFileName created succesfully"
    Write-Output ""
    return
}

function Get-PlifyRepositoryPublicKey() {
    param(
        [Parameter(Mandatory=$true)] [string] $Name
    )
    $openssl = Get-PlifyRepositoryOpenSSL
    $certDir = Get-PlifyRepositoryCertificateDir
    $certBaseName = "$certDir$($ds)$Name"

    # extract the public key from the public cert
    & $openssl x509 -in "$certBaseName.crt" -pubkey -noout > "$certBaseName.key.public" 2>&1 | Out-Null
    if ($LASTEXITCODE -gt 0) {
        throw "Failed to extract public key from certificate: $certBaseName.crt"
    }

    Update-PlifyRepository -Name $Name -Thumbprint (Get-FileHash -Path "$certBaseName.key.public" -Algorithm SHA256).Hash | Out-Null
}

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
        throw "Invalid PFX Path: file doesn't exist or is not a PFX file"
    }

    # make sure we don't restore a certifacte over an existing one unless forced
    if ( (Test-Path -Path "$certBaseName.key.private") -eq $true -and $Force -eq $false) {
        throw "Certificate already exists...skipping"
    }

    & $openssl pkcs12 -in $Path -nocerts -nodes -passin pass:$Password | & $openssl pkcs8 -nocrypt -out "$certBaseName.key.private" 2>&1 | Out-Null
    if ($LASTEXITCODE -gt 0) {
        throw "Error Restoring Private Key Certificate from PFX: $Path"
    }

    & $openssl pkcs12 -in $Path -nokeys -clcerts -passin pass:$Password | & $openssl x509 -out "$certBaseName.crt" 2>&1 | Out-Null
    if ($LASTEXITCODE -gt 0) {
        throw "Error Restoring Certificate from PFX: $Path"
    }

    & $openssl x509 -in "$certBaseName.crt" -pubkey -noout > "$certBaseName.key.public" | Out-Null
    if ($LASTEXITCODE -gt 0) {
        throw "Error Restoring Public Key from PFX: $Path"
    }

    Get-PlifyRepositoryPublicKey -Name $Name

    Write-Output ""
    Write-Output "Restored Certificate: $Path for repo: $Name"
    Write-Output ""
    return
}

function Get-PlifyRepositoryCacheFile() {
    return "$(PlifyConfiguration\Get-PlifyConfigurationDir -Scope 'Global')$($ds)repositorycache.json"
}

function Sync-PlifyRepository() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)] [switch] $Force
    )

    $cacheFile = Get-PlifyRepositoryCacheFile
    if ( (Test-Path -Path $cacheFile) -and $Force -eq $false) {
        $lastUpdate = (Get-Item -Path $cacheFile).LastWriteTimeUtc
        $currentTime = Get-Date -AsUTC
        if ($lastUpdate -gt $currentTime.AddDays(-1)) {
            Write-Output "Cache file has already been updated within the last day, skipping"
            Write-Output "  use: '@{Force=`$true}' to force an update now"
            return
        }
    }

    $EnabledRepos = Get-PlifyRepository | Where-Object { $_.Enabled -eq $true }
    $cache = @{}
    $start = Get-Date
    $r = 0
    foreach ($repo in $EnabledRepos) {
        # the sync process is very quick that write-progress just disapears too quickly to be useful.
        # using write-output to just display console messages for feedback
        Write-Progress -Activity "Syncrhonizing Plify Repositories" -Status "Processing $($r+1) of $($EnabledRepos.Count)" -PercentComplete (($r)/$EnabledRepos.Count*100) -CurrentOperation "Downloading Inventory: $($repo.Name)"
        
        $cache[$repo.Name] = @{}
        Write-Output "Processing Repository: $($repo.Name)  ($($repo.URL))"
        Write-Output "  Downloading Inventory"
        $indexContent = PlifyWeb\Get-PlifyWebContent -Url "$($repo.URL)/inventory.json"
        Write-Progress -Activity "Syncrhonizing Plify Repositories" -Status "Processing $($r+1) of $($EnabledRepos.Count)" -PercentComplete (($r)/$EnabledRepos.Count*100) -CurrentOperation "Updating Inventory: $($repo.Name)"
        if ( -not ([string]::IsNullOrEmpty($indexContent))) {
            Write-Output "  Reading Inventory"
            $index = ($indexContent | ConvertFrom-Json -Depth 5)
            Write-Output "  Processing Inventory"
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
    Write-Output "Updating Cache"
    $cache | ConvertTo-Json -Depth 5 -Compress | Out-File -FilePath $cacheFile
    $end = Get-Date
    Write-Output "Complete"
    Write-Debug " Update Process run time: $($end - $start)"
}

function New-PlifyRepositoryCertificate() {
    param(
        [Parameter(Mandatory=$true)] [string] $Name,
        [Parameter(Mandatory=$false)] [string] $Days = 3650, 
        [Parameter(Mandatory=$false)] [int] $KeySize = 4096,
        [Parameter(Mandatory=$false)] [switch] $Force
    )

    # only generate certs for existing repositories
    if ( $null -eq (Get-PlifyRepository -Name $Name) ) {
        throw "Repository $Name doesn't exist, please create that first"
    }

    $openssl = Get-PlifyRepositoryOpenSSL
    $config = Get-PlifyRepositoryOpenSSLConfig
    $certDir = Get-PlifyRepositoryCertificateDir
    $certBaseName = "$certDir$($ds)$Name"

    $subject = "/CN=$Name"

    # make sure we don't overwrite certs unless forced
    if ( (Test-Path -Path "$certBaseName.key.private") -eq $true -and $Force -eq $false ) {
        throw "Certificate for repository $Name already exists...skipping"
    }

    # we never regenerate certificates for plify default repo's
    if ($Name -eq "PlifyProd" -or $Name -eq "PlifyDev") {
        throw "Can't generate certificates for default Plify Repositories!!"
    }

    # generate the new private key and public cert
    & $openssl req -x509 -newkey rsa:$KeySize -keyout "$certBaseName.key.private" -out "$certBaseName.crt" -days $Days -nodes -subj $subject -config $config 2>&1 | Out-Null
    if ($LASTEXITCODE -gt 0) {
        Write-Error "Failed to generate new certificates: $certBaseName[.crt|.key.private]" -ErrorAction SilentlyContinue
        throw
    }

    Get-PlifyRepositoryPublicKey -Name $Name

    Write-Output ""
    Write-Output "Created Certificate for Repository: $Name"
    Write-Output ""
}