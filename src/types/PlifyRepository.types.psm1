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