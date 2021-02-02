function Build-PlifyStringFromHash() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)] [Hashtable] $hashtable
    )

    $hashString = "@{"

    if ($hashtable.Count -eq 0) {
        $hashString += "}"
        return $hashString
    }
    
    foreach ($item in $hashtable.GetEnumerator() | Sort-Object -Property Name) {
        if ($hashString.Length -gt 2) {
            $hashString += "; "
        }
        $hashString += "$($item.Key)=`"$($item.Value)`""
    }
    $hashString += "}"
    return $hashString
}

Export-ModuleMember -Function Build-PlifyStringFromHash