#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
BeforeAll {
    . $PSSCriptRoot\beforeAll.ps1
}

Describe "Get-PlifyRepository" {
    It "Should list two repositories by default - formatted" {
        $output = Plifyrepository\Get-PlifyRepository
        $output[1] | Should -BeLike "*Repository*Enabled*Description*"
        $output[2] | Should -BeLike "*PlifyDev*False*Official Dev Plify Repository*"
        $output[3] | Should -BeLike "*PlifyProd*True*Official Production Plify Repository*"
    }
}