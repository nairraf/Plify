#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
BeforeAll {
    . $PSSCriptRoot\..\beforeAll.ps1
}

Describe 'New-PlifyModule' {
    BeforeAll {
        function Remove-PlifyPesterTest() {
            if (Test-Path -Path "$plifyModuleRoot$($ds)Pester$($ds)PlifyPesterTest") {
                Remove-Item "$plifyModuleRoot$($ds)Pester" -Recurse -Force | Out-Null
            }

            if (Test-Path -Path "$plifyDevRoot$($ds)tests$($ds)Modules$($ds)PlifyPesterTest.Module.Tests.ps1") {
                Remove-Item "$plifyDevRoot$($ds)tests$($ds)Modules$($ds)PlifyPesterTest.Module.Tests.ps1" -Force | Out-Null
            }
        }
    }

    BeforeEach {
        Remove-PlifyPesterTest
    }

    AfterEach {
        Remove-PlifyPesterTest
    }

    it 'Should Create Module and Module directories' {
        PlifyModule\New-PlifyModule -Name PlifyPesterTest -ModuleRoot Pester 

        Test-Path -Path "$plifyModuleRoot$($ds)Pester$($ds)PlifyPesterTest" | Should -Be $true
        Test-Path -Path "$plifyModuleRoot$($ds)Pester$($ds)PlifyPesterTest$($ds)PlifyPesterTest.psm1" | Should -Be $true
        Test-Path -Path "$plifyModuleRoot$($ds)Pester$($ds)PlifyPesterTest$($ds)PlifyPesterTest.eng.help" | Should -Be $true
        Test-Path -Path "$plifyModuleRoot$($ds)Pester$($ds)PlifyPesterTest$($ds)Get-PlifyPesterTest.eng.help" | Should -Be $true
        Test-Path -Path "$plifyDevRoot$($ds)tests$($ds)Modules$($ds)PlifyPesterTest.Module.Tests.ps1" | Should -Be $true
    }

}