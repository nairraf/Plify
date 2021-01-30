#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
BeforeAll {
    . $PSSCriptRoot\beforeAll.ps1
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
    ) {
        param ($Name, $Expected)

        $GetVerb = PlifyRouter\Get-PlifyVerb($Name)
        $GetVerb | Should -BeExactly $Expected
    }
}