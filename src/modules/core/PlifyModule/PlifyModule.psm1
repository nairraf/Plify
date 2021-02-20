$defatulModuleContents = @'
# import all our external module functions into the modules current scope on module load
foreach ($file in (Get-ChildItem -Path "$PSScriptRoot$($ds)*.ps1" -Recurse)) {  
    . $file.FullName
}

function Get-__FULLMODULENAME__() {

}
'@

$DefaultModuleTestContents = @'
#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
BeforeAll {
    . $PSSCriptRoot\..\beforeAll.ps1
}
'@

$DefaultModuleHelpContents = @'

## __MODULENAME__ module help
    Default Help for __MODULENAME__

## Usage
    plify __MODULENAME__ <action> @{ ActionParamater="SomeValue" }

## Available Actions
    Action      Action Parameters               Description
    ------      -----------------               -----------

## Available Shortcuts
__MODULESHORTCUTS__:Plify<ModuleName>
'@

$DefaultModuleActionHelpContents = @'

### plify __MODULENAME__ get help
    default help file for __MODULENAME__ get

### Valid Action Parameters

#### Examples
    plify __MODULENAME__ get            - gets __MODULENAME__

#### Action Aliases
    these aliases can be used instead of get:
        __GETALIASES__
'@


function New-PlifyModule() {
    param(
        [Parameter(Mandatory=$true)] [string] $Name,
        [Parameter(Mandatory=$false)] [string] $ModuleRoot = "App"
    )

    # make sure the first letter is a capitalized
    $Name = "$($Name[0].ToString().ToUpper())$($Name[1..($Name.Length)] -Join '')"

    # make sure that our module name is good
    if (-not ($Name.StartsWith('Plify'))) {
        $Name = "Plify$Name"
    }

    # get out simple module name
    $simpleModuleName = $Name.Replace("Plify", "")

    # make sure the module directory doesn't exist and then create it
    $ModuleDirPath = "$plifyModuleRoot$($ds)$ModuleRoot$($ds)$Name"
    if (-not (Test-Path -Path $ModuleDirPath)) {
        Write-Output "Creating New Module Directory: $ModuleDirPath"
        New-Item -Path $ModuleDirPath -ItemType Directory | Out-Null
    }

    # make sure the default module file doesn't exist and create it
    $defaultPSModule = "$ModuleDirPath$($ds)$Name.psm1"
    if (-not (Test-Path -Path $defaultPSModule)) {
        Write-Output "Creating Default PS Module: $defaultPSModule"
        $defatulModuleContents.Replace('__FULLMODULENAME__', $Name) | Out-File -FilePath $defaultPSModule 
    }

    # make sure the default module help file doesn't exist and create it
    $defaultModuleHelp = "$ModuleDirPath$($ds)$Name.eng.help"
    if (-not (Test-Path -Path $defaultModuleHelp)) {
        Write-Output "Creating Default Module Help File: $defaultModuleHelp"
        $DefaultModuleHelpContents.Replace('__MODULENAME__', $simpleModuleName) | Out-File -FilePath $defaultModuleHelp 
    }

    # make sure the default get action help file doesn't exist and create it
    $defaultModuleGetActionHelp = "$ModuleDirPath$($ds)Get-$Name.eng.help"
    if (-not (Test-Path -Path $defaultModuleGetActionHelp)) {
        Write-Output "Creating Default Get Action Help File: $defaultModuleGetActionHelp"
        $DefaultModuleActionHelpContents.Replace('__MODULENAME__', $simpleModuleName) | Out-File -FilePath $defaultModuleGetActionHelp 
    }

    # make sure the default module test file doesn't exist and create it
    $defaultModuleTestFile = "$plifyDevRoot$($ds)tests$($ds)Modules$($ds)$Name.Module.Tests.ps1"
    if (-not (Test-Path -Path $defaultModuleTestFile)) {
        Write-Output "Creating Default Module Test File: $defaultModuleTestFile"
        $DefaultModuleTestContents | Out-File -FilePath $defaultModuleTestFile
    }
}

Export-ModuleMember -Function New-PlifyModule