# import all our external module functions into the modules current scope on module load
foreach ($file in (Get-ChildItem -Path "$PSScriptRoot$($ds)*.ps1" -Recurse)) {  
    . $file.FullName
}

function Get-PlifyWebContent() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] [string] $Url
    )

    try {
        $content = Invoke-WebRequest -Uri $Url | Select-Object -ExpandProperty Content
        return $content
    } catch {
        return ""
    }    
}

function Get-PlifyWebLargeFile() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] [string] $Url,
        [Parameter(Mandatory=$true)] [string] $FilePath,
        [Parameter(Mandatory=$false)] [string] $sha256
    )

    $sourceFileName = ($url.split('/') | Select-Object -Last 1)
    $ActivityTitle = "file download: $sourceFileName"
    try {
        $uri = New-Object "System.Uri" "$Url"
        $request = [System.Net.HttpWebRequest]::Create($uri)
        $request.set_timeout(30000) # 30 second timeout
        $response = $request.GetResponse()
        $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
        $responseStream = $response.GetResponseStream()
        $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $FilePath, Create
        $buffer = New-Object byte[] 1000KB # able to achieve ~1Gbps with a 1000KB buffer
        $count = $responseStream.Read($buffer,0,$buffer.length)
        $downloadedBytes = $count
        while ($count -gt 0) {
            $targetStream.Write($buffer, 0, $count)
            $count = $responseStream.Read($buffer,0,$buffer.Length)
            $downloadedBytes = $downloadedBytes + $count
            $downloadedKB = [System.Math]::Floor($downloadedBytes/1024)
            $percentComplete = (( $downloadedKB / $totalLength)  * 100)
            Write-Progress -Activity $ActivityTitle -Status "Downloaded ($('{0:N0}' -f $downloadedKB)KB of $('{0:N0}' -f $totalLength)KB)" -PercentComplete $percentComplete -CurrentOperation "Downloading"
        }
        Start-Sleep -Seconds 1 # Write-Progress can't deal with updates if they are too fast, so sleep a little
        $targetStream.Flush()
        $targetStream.Close()
        $targetStream.Dispose()
        $responseStream.Dispose()
    } catch {
        return $false
    } finally {
        Write-Progress -Activity $ActivityTitle -Status "Download Complete" -PercentComplete 100 -CurrentOperation "Download Complete"
        Start-Sleep -Seconds 1 # Write-Progress can't deal with updates if they are too fast, so sleep a little
    }

    if ([string]::IsNullOrEmpty($sha256) -eq $false) {
        Write-Progress -Activity $ActivityTitle -Status "Verifying File...  (this may take a few minutes)" -PercentComplete 100 -CurrentOperation "Verifying File Download"
        $downloadedSHA256 = Get-FileHash -Algorithm SHA256 -Path $FilePath
        Write-Debug "downloaded SHA256: $($downloadedSHA256.Hash)" 
        if ($downloadedSHA256.Hash -eq $sha256) {
            return $true
        } else {
            return $false
        }
    }
}