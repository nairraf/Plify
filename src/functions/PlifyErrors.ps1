function Global:Write-PlifyErrors() {
    $ogForeground = [console]::ForegroundColor
    [console]::ForegroundColor = "Red"
    ""
    "Errors Encountered:"
    "-------------------"
    [console]::ForegroundColor = "Yellow"
    foreach ($e in $error) {
        $lineNum = $e.InvocationInfo.ScriptLineNumber
        $spacer = ""
        while ($spacer.Length -lt $lineNum.Length) {
            $spacer += " "
        }
        "Script: $($e.InvocationInfo.ScriptName)"
        "  line #$($lineNum): $($e.InvocationInfo.Line.Trim())"
        "       $($spacer)msg: $($e.Exception.Message)"
        " "
    }
    [console]::ForegroundColor = $ogForeground
    ""
}