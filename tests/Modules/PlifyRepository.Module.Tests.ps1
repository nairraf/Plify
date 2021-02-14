#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
BeforeAll {
    . $PSSCriptRoot\..\beforeAll.ps1
}

Describe "Get-PlifyRepository" {
    It "Should list two repositories by default - formatted" {
        $output = Plifyrepository\Get-PlifyRepository
        $output.Count | Should -Be 2
    }
}

Describe 'Set-PlifyRepository' {
    It 'Should Add a new Repository' {
        
    }
}