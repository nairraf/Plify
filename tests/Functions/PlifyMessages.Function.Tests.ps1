#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
BeforeAll {
    . $PSSCriptRoot\..\beforeAll.ps1
}

Describe 'Get-PlifyMessage-English' {
    BeforeAll {
        Mock Get-PlifyOfficialTranslations { return @('eng') }
        $Script:PlifyMessages = @{
            eng = @{
                Default = "Default Plify Message: "
                Test = @{
                    SpecificMessageTest = "This is to test retrieving a specific message"
                    SpecificMessageTestWithArgs = "This is to test retrieving a specific message with args: __FIRST__, __SECOND__"
                }
            }
        }
    }
    It 'Should Return the default Plify Message' {
        Get-PlifyMessage -Module "bad" -Message "bad" | Should -Be "Default Plify Message: @{}"
        $Replacements = @{first="first"; second="second"}
        Get-PlifyMessage -Module "bad" -Message "bad" -Replacements $Replacements | Should -Be 'Default Plify Message: @{first="first"; second="second"}'
    }

    It 'Should Return a specific Message' {
        Get-PlifyMessage -Module "Test" -Message "SpecificMessageTest" | Should -Be "This is to test retrieving a specific message"
        $Replacements = @{first="first"; seCOnd="second"} # test cases with keys
        Get-PlifyMessage -Module "Test" -Message "SpecificMessageTestWithArgs" -Replacements $Replacements | Should -Be "This is to test retrieving a specific message with args: first, second"
    }
}