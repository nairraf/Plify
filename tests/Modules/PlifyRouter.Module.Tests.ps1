#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
BeforeAll {
    . $PSSCriptRoot\..\beforeAll.ps1

    Get-Module -Name PlifyTestModule | Remove-Module
    New-Module -Name PlifyTestModule -ScriptBlock {
        Function TestAction { return "TestAction" }
    } | Import-Module -Force
}

Describe 'Get-PlifyVerb Returns Proper Verb' {
    It 'parameter <Name> returns <Expected>' -ForEach @(
        @{ Name = 'list'; Expected = 'Get' }
        @{ Name = 'show'; Expected = 'Get' }
        @{ Name = 'SHoW'; Expected = 'Get' } # to test case
        @{ Name = 'ls'; Expected = 'Get' }
        @{ Name = 'get'; Expected = 'Get' }
        @{ Name = 'new'; Expected = 'New' }
        @{ Name = 'add'; Expected = 'New' }
        @{ Name = 'create'; Expected = 'New' }
        @{ Name = 'delete'; Expected = 'Remove' }
        @{ Name = 'init'; Expected = 'Initialize' }
        @{ Name = 'initialize'; Expected = 'Initialize' }
        @{ Name = 'Update'; Expected = 'Update' }
        @{ Name = 'modify'; Expected = 'Update' }
        @{ Name = 'mod'; Expected = 'Update' }
        @{ Name = 'upd'; Expected = 'Update' }
        @{ Name = 'sync'; Expected = 'Sync' }
        @{ Name = 'synchronize'; Expected = 'Sync' }
        @{ Name = 'pull'; Expected = 'Sync' }
        @{ Name = 'build'; Expected = 'Build' }
        @{ Name = 'gen'; Expected = 'Build' }
        @{ Name = 'generate'; Expected = 'Build' }
    ) {
        param ($Name, $Expected)

        $GetVerb = PlifyRouter\Get-PlifyVerb($Name)
        $GetVerb | Should -BeExactly $Expected
    }
}

Describe 'Get-PlifyModule returns expected Modules' {
    BeforeEach {
        Get-Module PlifyRouter | Remove-Module
        Import-Module PlifyRouter
        Mock Get-Module { return 'PlifyGood' } -ParameterFilter { $Name -eq 'plifygood' } -ModuleName PlifyRouter
        Mock Get-Module { } -ParameterFilter { $Name -eq 'bad' } -ModuleName PlifyRouter
    }
    It 'Module <Name> returns <Expected>' -ForEach @(
        @{ Name = "plifygood"; Expected = "PlifyGood"}
        @{ Name = "bad"; Expected = $null }
    ) {
        param ($Name, $Expected)

        PlifyRouter\Get-PlifyModule -ModuleName $Name | Should -Be $Expected
    }
}


Describe 'Get-PlifyModuleAction' {
    It 'Returns Valid ModuleAction' {
        $Action = PlifyRouter\Get-PlifyModuleAction -Module (Get-Module -Name PlifyTestModule) -ActionName "TestAction"
        $Action | Should -Be (Get-Module -Name PlifyTestModule).ExportedCommands["TestAction"]
    }

    It 'Returns Null ModuleAction' {
        $Action = PlifyRouter\Get-PlifyModuleAction -Module (Get-Module -Name PlifyTestModule) -ActionName "BadAction"
        $Action | Should -Be $null
    }
}

Describe 'Build-PlifyModuleName' {

    It 'Returns "Plify<name>"' {
        PlifyRouter\Build-PlifyModuleName -ModuleName "Test" | Should -Be "PlifyTest"
    }

    It 'Returns valid Module for an alias' -ForEach @(
        @{ Alias="conf";Module="Configuration"}
        @{ Alias="config";Module="Configuration"}
        @{ Alias="configuration";Module="Configuration"}
        @{ Alias="repo";Module="Repository"}
        @{ Alias="repoSitory";Module="Repository"}
    ){
        param($Alias, $Module)
        PlifyRouter\Build-PlifyModuleName -ModuleName $Alias | Should -Be "Plify$($Module)"
    }
}

Describe 'Build-PlifyActionName' {

    It 'Returns proper Plify function for Requested Action: <Name>' -ForEach @(
        @{ Name="show"; Expected="Get-PlifyTestModule" }
        @{ Name="add"; Expected="New-PlifyTestModule" }
    ) {
        param($Name, $Expected)
        PlifyRouter\Build-PlifyActionName -Module (Get-Module -Name PlifyTestModule) -ActionName $Name | Should -Be $Expected
    }
}