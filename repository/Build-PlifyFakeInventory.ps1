#Requires -Modules powershell-yaml
param(
    [Parameter(Mandatory=$false, Position=0)] [int] $NumFakes = 1
)

$Script:Repository = @{}
$inventoryFile = "$PSScriptRoot$($ds)inventory.json"

$Script:osDetails = @{
    linux = @(
        "centos:8:3:lts","centos:8:5:lts","centos:7:6:lts","centos:7:7:lts"
        "debian:8:0:lts","debian:9:0:lts","debian:10:0:lts"
        "ubuntu:20:04:lts","ubuntu:20:10","ubuntu:18:04:lts"
    )
    windows = @(
        "windows server 2019:10:0:LTS", "windows server 2016:10:0:LTS","windows 10:0","windows server 2012 R2:6:3:lts"
    )
}

function Get-PlifyRandomString() {
    param(
        [Parameter(Mandatory=$true, Position=0)] [int] $NumChars
    )

    $randString = ""
    $randString += ( ((48..57) + (65..90) + (97..122)) | Get-Random -Count $NumChars | ForEach-Object {[char]$_}) -join ""


    return $randString
}

function Add-FakeOS() {
    $family = Get-Random "linux","windows"
    $osString = $Script:osDetails.$family[(Get-Random (0..((($Script:osDetails.$family).Count)-1)))]
    $os = $osString.Split(':')
    $osName = $os[0]
    $osMajorVersion = $os[1]
    $osMinorVersion = $os[2]
    if ($os.Count -eq 4) {
        $osLTS = $true
    } else {
        $osLTS = $false
    }
    $packageFile = "$($osName)_$($osVersion)_$(Get-PlifyRandomString 10).7z"
    $Script:Repository[$packageFile] = @{
        package = @{
            relative_repo_path = "$family/$osName/$packageFile"
            hash = (Get-PlifyRandomString 40).ToString().ToUpper()
        }
        Virtualization = @{
            hyperv = @{
                generation = 2
            }
        }
        image = @{
            tags = @("server","minimal")
            hash = (Get-PlifyRandomString 40).ToString().ToUpper()
            maintainer = @{
                url = "www.plify.com"
                name = "Ian Farr"
            }
            lastChange = (Get-PlifyRandomString 40).ToString().ToUpper()
            version = (Get-Random (1..100))
        }
        os = @{
            name = $osName
            lts = $osLTS
            family = $family
            version_major = $osMajorVersion
            version_minor = $osMinorVersion
        }
    }
}
Write-Output "Adding $NumFakes Fakes.."
for ($i=0;$i -lt $NumFakes;$i++) {
    if ($i % 100 -eq 0) {
        write-Output "  Added $i Fakes"
    }
    Add-FakeOS
}
Write-Output "Writing JSON..."
$Repository | ConvertTo-Json -Depth 5 -Compress  | Out-File -FilePath $inventoryFile