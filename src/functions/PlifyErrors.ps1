function Global:Write-PlifyErrors() {
    $ogForeground = [console]::ForegroundColor
    [console]::ForegroundColor = "Red"
    ""
    "Errors Encountered:"
    [console]::ForegroundColor = "Yellow"
    foreach ($e in $error) {
        "  $($e.ToString())"
    }
    [console]::ForegroundColor = $ogForeground
    ""
}