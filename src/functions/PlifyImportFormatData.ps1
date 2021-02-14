function Global:Update-PlifyFormatData() {
    $FomatFiles = Get-ChildItem -Path "$plifyRoot$($ds)*.ps1xml" -Recurse

    foreach ( $formatFile in $FomatFiles ) {
        $TypeName = $formatFile.BaseName
        if ( (Get-FormatData -TypeName $TypeName).Count -eq 0) {
            Write-Debug "Updating Format:  $formatFile"
            Update-FormatData -PrependPath $formatFile.FullName
        }
    }
}