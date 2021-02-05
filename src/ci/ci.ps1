param(
    [string[]]$Tasks
)
 
function Invoke-CISetup()
{
    $policy = Get-PSRepository -Name "PSGallery" | Select-Object -ExpandProperty "InstallationPolicy"
    if($policy.ToLower() -ne "trusted") {
        Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
        Write-Output "Setting Repository PSGalery to trusted"
    }

    $pesterModules = Get-Module -name Pester -ListAvailable
    $updatePester = $true
    foreach ($version in $pesterModules.Version.Major) {
        if ($version -ge 5) {
            $updatePester = $false
        }
    }
    if ($updatePester) {
        Write-Output "Installing Module: Pester"
        Install-Module -Name Pester -Scope CurrentUser -Force -SkipPublisherCheck
    }

    if ( (Get-Module -name PSScriptAnalyzer -ListAvailable).Count -eq 0) {
        Write-Output "Installing Module: PSScriptAnalyzer"
        Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
    }

    Import-Module PSScriptAnalyzer
    Import-Module Pester -MinimumVersion 5.0.0
}
 
function Invoke-CodeAnalysis
{
    Invoke-ScriptAnalyzer -Path (Get-Item $PSScriptRoot).Parent.FullName -Severity @('Error', 'Warning') -Recurse -OutVariable issues
    $errors   = $issues.Where({$_.Severity -eq 'Error'})
    $warnings = $issues.Where({$_.Severity -eq 'Warning'})
    if ($errors) {
        Write-Error "There were $($errors.Count) errors and $($warnings.Count) warnings total." -ErrorAction Stop
    } else {
        Write-Output "There were $($errors.Count) errors and $($warnings.Count) warnings total."
    }
}
 
function Invoke-CodeTest
{
    # srcDirs is used for CodeCoverage. This should be the path where all your source code is
    $ProjectDir = (Get-Item $PSScriptRoot).Parent.Parent.FullName
    $srcDirs = (Get-ChildItem -Path "$ProjectDir\src" -Filter "*.ps*1" -Exclude @("ci.ps1", "plify.ps1") -Recurse).FullName
    # testDirs is where all your paster test files are
    $testDirs = @("$ProjectDir\tests")

    # Create our Pester configuration
    $configuration = [PesterConfiguration]::Default
    $configuration.Run.Path = $testDirs
    $configuration.CodeCoverage.Enabled = $true
    $configuration.CodeCoverage.Path = $srcDirs
    $configuration.Run.Exit = $false
    $configuration.Run.PassThru = $true
    $configuration.Output.Verbosity.Value = "Normal" # Normal, Detailed, Diagnostic
    $results = Invoke-Pester -Configuration $configuration

    # CodeCoverage outputs a report called coverage.xml
    # the XML totals all the missed and covered portions of all source files
    # add them up and report a coverage %
    $CoverageXML = [xml](Get-Content coverage.xml)
    $missed = 0
    $covered = 0
    foreach ($miss in $CoverageXML.report.counter.missed) {
        $missed += $miss
    }

    foreach ($hit in $CoverageXML.report.counter.covered) {
        $covered += $hit
    }
    Write-Output ""
    Write-Output "Code Coverage Details:"
    Write-Output ""
    Write-Output "`tType`t`tMissed`t`tCovered"
    foreach ($counterType in $CoverageXML.report.counter) {
        $tabs = "`t`t"
        if ($CounterType.type.length -gt 6) {
            $tabs="`t"
        }
        Write-Output "`t$($CounterType.type)$tabs$($CounterType.missed)`t`t$($CounterType.covered)"
    }
    Write-Output "`t---------------------------------------"
    Write-Output "`tTotals`t`t$missed`t`t$covered"
    Write-Output ""
    Write-Output "Total CodeCoverage: $([math]::Round($covered/($missed+$covered)*100, 2))%"
    Write-Output ""
    if ($results.FailedCount -gt 0) {
        exit $results.FailedCount
    }

    exit
}
 
function Deploy-Module
{
    Write-Output "Deploying Code"
}
 
function Get-GitCommitMessage
{
    git log -1 --pretty=%B
}

## Setup Runner Environment
Invoke-CISetup

foreach($task in $Tasks){
    switch($task)
    {
        "analyze" {
            Write-Output "Analyzing Scripts..."
            Invoke-CodeAnalysis
        }
        "test" {
            Write-Output "Running Pester Tests..."
            Invoke-CodeTest
        }
        "deploy" {
            $message = Get-GitCommitMessage
            if($message.ToLower().Contains("[deploy]")) {
                Write-Output "Deploying Modules..."
                Deploy-Module
            }
            else {
                Write-Output "Skipping Deploy..."
            }
        }
    }
}