#Requires -Modules powershell-yaml
param(
    [Parameter(Mandatory=$false)] [switch] $Force
)

<#
    Plify Repository Inventory Builder
#>

## Functions




## Main
$error.Clear()

$Repository = @{
    PlifyRepo = @{ Version = 1.0 }
    Repository = @{}
}

$ds = [System.IO.Path]::DirectorySeparatorChar
$RepoRoot = "$PSScriptRoot$($ds)root"
$inventoryFile = "$RepoRoot$($ds)inventory.yml"
if (Test-Path -Path $inventoryFile) {
    $oldInventory = ConvertFrom-Yaml -Yaml (Get-Content -Path $inventoryFile -Raw)
} else {
    $oldInventory = @{}
}
$ImageRoot = "$PSScriptRoot$($ds)images"
$7zip = "$PSScriptRoot$($ds)bin$($ds)7za.exe"

Write-Output ""
foreach ($image in (Get-ChildItem -Path "$ImageRoot$($ds)*.vhd*" -Recurse)) {
    $yaml = $image.DirectoryName + $ds + $image.BaseName + ".yml"
    $packageName = $image.BaseName + ".7z"

    if (Test-Path -Path $yaml) {
        Write-Output "Processing: $image"
        $lastChange = [string]($image.LastWriteTimeUTC).Year + `
                      ($image.LastWriteTimeUTC).Month + `
                      ($image.LastWriteTimeUTC).Day + `
                      ($image.LastWriteTimeUTC).Hour + `
                      ($image.LastWriteTimeUTC).Minute + `
                      ($image.LastWriteTimeUTC).Second
        $stringAsStream = [System.IO.MemoryStream]::new()
        $writer = [System.IO.StreamWriter]::new($stringAsStream)
        $writer.write($lastChange)
        $writer.Flush()
        $stringAsStream.Position = 0
        $lastChangeHash = (Get-FileHash -InputStream $stringAsStream -Algorithm SHA256).Hash
        $imageHash = ""
        $packageHash = ""

        if ($lastChangeHash -eq $oldInventory.Repository.$packageName.image.lastChange -and $Force -eq $false) {
            if(-not ([string]::IsNullOrEmpty($oldInventory.Repository.$packageName.image.hash)) -and 
                -not ([string]::IsNullOrEmpty($oldInventory.Repository.$packageName.package.hash))) {
                    Write-Output "  No change deteted for image: $image"
                    Write-Output "      will not re-compute hashes, use '-Force' to recompute hashes"
                    $imageHash = $oldInventory.Repository.$packageName.image.hash
                    $packageHash = $oldInventory.Repository.$packageName.package.hash
                }
        }

        if( [string]::IsNullOrEmpty($imageHash)) {
                Write-Output "  Computing Hash for: $image"
                $imageHash = (Get-FileHash -Algorithm SHA256 -Path $image.FullName).Hash
        }

        try {
            $imgYaml = ConvertFrom-Yaml -Yaml (Get-Content -Path $yaml -Raw)
            $Repository.Repository[$packageName] = @{
                Virtualization = $imgYaml.Virtualization
                os = $imgYaml.os
                image = $imgYaml.image
            }
            $Repository.Repository[$packageName]["package"] = @{}
            $Repository.Repository[$packageName]["image"]["lastChange"] = $lastChangeHash
            $Repository.Repository[$packageName]["image"]["hash"] = $imageHash
            $packageRelativePath = $Repository.Repository[$packageName]["os"]["family"] + $ds + $Repository.Repository[$packageName]["os"]["name"]
            $packagePath = $RepoRoot + $ds + $packageRelativePath
            $packageFullName = $packagePath + $ds + $packageName
            if ( -not (Test-Path -Path $packagePath )) {
                Write-Output "  Creating Repository Package Path: $packagePath"
                New-Item -Path $packagePath -ItemType Directory | Out-Null
            }
            if( [string]::IsNullOrEmpty($packageHash)) {
                Write-Output "  Creating Package: $packageName"
                & $7zip a -y "$packageFullName" "$($image.FullName)" 2>&1 | Out-Null
                if ($LASTEXITCODE -gt 0) {
                    Write-Output "    Error Creating package: $packageFullName"
                } else {
                    write-Output "  Computing hash for package: $packageName"
                    $packageHash = (Get-FileHash -Algorithm SHA256 -Path $packageFullName).Hash
                }
            }
            $Repository.Repository[$packageName]["package"]["hash"] = $packageHash
            $Repository.Repository[$packageName]["package"]["relative_repo_path"] = $packageRelativePath.Replace($ds,'/') + '/' + $packageName
        } catch {
            Write-Error "Error Processing: $image"
            $error
            exit 1
        }
    }
}


Write-Output "Writing new inventory file: $inventoryFile"
# write our yaml repository file
$Repository | ConvertTo-Yaml -OutFile $inventoryFile -Force

Write-Output "done"
Write-Output ""