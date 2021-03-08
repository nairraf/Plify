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

class Plify {
    [int] $ExitCode
    [PlifyStatus] $Status
    
    PlifyReturnBasic() {
        $this.Status = [PlifyStatus]::OK
        $this.ExitCode = [int][PlifyStatus]::OK
    }
    PlifyReturnBasic(
        [PlifyStatus] $status
    ) {
        $this.ExitCode = [int]$status
        $this.Status = $status
    }
}

class PlifyReturn : Plify {
    [string] $Message
    [string] $Content
    [PlifyNextCall] $NextCall
    PlifyReturn(){}
    PlifyReturn(
        [int] $exitcode,
        [PlifyStatus] $status,
        [string] $message,
        [PlifyNextCall] $nextCall,
        [string] $content
    ) {
        $this.SetStatus($status)
        $this.Message = $message
        $this.NextCall = $nextCall
        $this.Content = $content
    }
    PlifyReturn(
        [PlifyStatus] $status,
        [string] $message
    ) {
        $this.SetStatus($status)
        $this.Message = $message
    }
    PlifyReturn(
        [PlifyStatus] $status,
        [string] $message,
        [PlifyNextCall] $nextCall
    ) {
        $this.SetStatus($status)
        $this.Message = $message
        $this.NextCall = $nextCall
    }

    [void]SetStatus([PlifyStatus]$status) {
        $this.Status = $status
        $this.ExitCode = [int]$status
    }
}