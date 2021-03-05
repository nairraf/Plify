# put PlifyMessages hashtable in script scope so that Get-PlifyMessage has access to it
# this holds the translations for all plify console messages for all modules
$Script:PlifyMessages = @{
    eng = @{
        Default = "Plify Encountered an Error: "
        Repository = @{
            AddRepositorySuccess = "Added New Plify Repository: __NAME__"
            BackupFileExists = "BackupFile: __FILEPATH__ already exists...skipping"
            BackupFailed = "Failed backingup certificate to __FILEPATH__"
            BackupSuccess = "BackupFile: __FILEPATH__ created succesfully"
            CertificateGenSuccess = "Created Certificate for Repository: __NAME__"
            CertificateGenFailed = "Failed to generate new certificate: __CERTNAME__.[crt|key.private|key.public]"
            ErrorCertFilesNotFound = "Certificate files not found for repository: __NAME__"
            ErrorRestoreCertificate = "Error Restoring Certificate from PFX: __PATH__"
            ErrorRestorePrivateKey = "Error Restoring Private Key Certificate from PFX: __PATH__"
            ErrorRestorePublicKey = "Error Restoring Public Key from PFX: __PATH__"
            ErrorExtractPublicKey = "Error Extracting Public Key for repository: __REPO__"
            InvalidPFXPath = "Invalid PFX: file doesn't exist or is not a PFX file"
            NoCertificateGenForDefaultRepos = "Can't generate certificates for default Plify Repositories!!"
            NoOverwritingCertificates = "Certificate for repository __NAME__ already exists...skipping"
            PFXExists = "PFX Archive already exists...skipping"
            RemoveRepositorySuccess = "Removed Plify Repository: __NAME__"
            RepositoryNotExists = "Repository __NAME__ doesn't exist, please create that first"
            RestoredCertificate = "Restored Certificate: __PATH__ for repo: __NAME__"
            SyncAlreadyRan = "Cache file has already been updated within the last day, skipping. use: '@{Force=`$true}' to force an update now"
            SyncSuccess = "Synchronized: __REPOS__"
            UpdatedRepo = "Updated Repository: __NAME__"
        }
    }
}

function Global:Get-PlifyMessage() {
    param(
        [Parameter(Mandatory=$true)] [string] $Module,
        [Parameter(Mandatory=$true)] [string] $Message,
        [Parameter(Mandatory=$false)] [hashtable] $Replacements = @{}
    )

    $lang = Get-PlifyTranslation
    if ($null -ne $PlifyMessages.$lang.$Module.$Message) {
        $msg = $PlifyMessages.$lang.$Module.$Message
        if ($Replacements.Count -gt 0) {
            foreach ($key in $Replacements.Keys){
                $label = ("__$($key)__").ToUpper()
                $msg = $msg.Replace($label, $Replacements.$key)
            }
        }
        return $msg 
    }
    
    return $PlifyMessages.$lang.Default + (Build-PlifyStringFromHash -hashtable $Replacements)
}