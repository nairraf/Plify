# put PlifyMessages hashtable in script scope so that Get-PlifyMessage has access to it
# this holds the translations for all plify console messages for all modules
$Script:PlifyMessages = @{
    eng = @{
        Default = "Plify Encountered an Error: "
        Repository = @{
            RepositoryNotExists = "Repository __NAME__ doesn't exist, please create that first"
            CertificateGenFailed = "Failed to generate new certificates: __CERTNAME__[.crt|.key.private]"
            NoCertificateGenForDefaultRepos = "Can't generate certificates for default Plify Repositories!!"
            NoOverwritingCertificates = "Certificate for repository __NAME__ already exists...skipping"
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