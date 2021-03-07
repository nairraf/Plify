using module .\PlifyBase.types.psm1

class PlifyRepoSync:PlifyReturn {
    [string] $Seconds

    PlifyRepoSync(
        [PlifyStatus] $status,
        [string] $message,
        [string] $seconds
    ) : base($status, $message) {
        $this.Seconds = $seconds
    }
}

class PlifyRepository:Plify {
    [string] $Name
    [bool] $Enabled
    [string] $Description
    [string] $URL
    [string] $Thumbprint
    PlifyRepository() : base() {}
}