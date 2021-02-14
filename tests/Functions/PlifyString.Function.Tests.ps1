#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
BeforeAll {
    . $PSSCriptRoot\..\beforeAll.ps1
}

Describe "Build-PlifyStringFromHash" {
    BeforeAll {
        $exmapleHash = @{ Beta="Test One"; Alpha="Test Two"; Omega="Test three"; Delta="Test Four" }
        $returnString = '@{Alpha="Test Two"; Beta="Test One"; Delta="Test Four"; Omega="Test three"}'
        $defaultString = '@{}'
    }

    It "Returns String Matching Hashtable keys sorted" {
        Build-PlifyStringFromHash $exmapleHash | Should -Match $returnString
    }

    It "Returns default string on empty hashtable" -Foreach @(
        @{ Table= @{} }
    ) {
        param($Table)
        Build-PlifyStringFromHash $Table | Should -Match $defaultString
    }
}