enum PlifyStatus {
    OK = 0
    SUCCESS = 0
    WARNING = 1
    ERROR = 2
}

class PlifyNextCall {
    [string] $Module
    [string] $Action
    [hashtable] $ActionParams
    PlifyNextCall(){}
    PlifyNextCall(
        [string] $module,
        [string] $action
    ) {
        $this.Module = $module
        $this.Action = $action
    }
    PlifyNextCall(
        [string] $module,
        [string] $action,
        [hashtable] $actionParams
    ) {
        $this.Module = $module
        $this.Action = $action
        $this.ActionParams = $actionParams
    }
}

class PlifyReturn {
    [int] $ExitCode
    [PlifyStatus] $Status
    [string] $Message
    [PlifyNextCall] $NextCall
    PlifyReturn(){}
    PlifyReturn(
        [int] $exitcode,
        [PlifyStatus] $status,
        [string] $message,
        [PlifyNextCall] $nextCall
    ) {
        $this.ExitCode = $exitcode
        $this.Status = $status
        $this.Message = $message
        $this.NextCall = $nextCall
    }
    PlifyReturn(
        [PlifyStatus] $status,
        [string] $message
    ) {
        $this.ExitCode = [int]$status
        $this.Status = $status
        $this.Message = $message
    }
    PlifyReturn(
        [PlifyStatus] $status,
        [string] $message,
        [PlifyNextCall] $nextCall
    ) {
        $this.ExitCode = [int]$status
        $this.Status = $status
        $this.Message = $message
        $this.NextCall = $nextCall
    }
}