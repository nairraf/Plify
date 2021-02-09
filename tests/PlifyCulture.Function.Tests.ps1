#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
BeforeAll {
    . $PSSCriptRoot\beforeAll.ps1
}

Describe 'Get-PlifyTranslation' {
    BeforeAll {
        Mock Get-PlifyOfficialTranslations { return @('eng', 'fre') }
        
    }
    It 'Should Return <ISOValue> with culture <Culture>' -Foreach @(
        @{Culture="eng"; ISOValue="eng"}
        @{Culture="fre"; ISOValue="fre"}
        @{Culture="ger"; ISOValue="eng"}
    ){
        param ($Culture, $ISOValue)
        Mock Get-Culture { return @{ThreeLetterISOLanguageName=$Culture} }
        Get-PlifyTranslation | Should -Be $ISOValue
    }
}