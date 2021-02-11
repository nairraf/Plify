#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
BeforeAll {
    # we do not do anything in this before all, as we are testing the bootstrap process, not using it yet
}

Describe 'Invoke-PlifyBootstrap' {
    BeforeEach {
        # make sure that all plify Modules are not loaded in current scope
        Get-Item -Path Function:\*Plify* | Remove-Item -ErrorAction SilentlyContinue

        # we set CallInvoke to false as we want to test that specifically
        # if CallInvoke is true, beforeAll.Funcion.ps1 will auto call Invoke-PlifyBootstrap for us, which we don't want for these tests
        . $PSSCriptRoot\beforeAll.ps1 -CallInvoke $false
    }

    it 'Plify Functions should not exist in Global Scope Yet' {
        # boot strap contains two plify functions, so only those should exist at this point
        (Get-Item -Path Function:\*Plify*).Count | Should -Be 3
    }

    it 'Plify Functions should now exist in Global Scope' {
        # Invoke the bootstrap
        Invoke-PlifyBootstrap

        # we should now have more than the default 2 functions, meaning we have successfully imported the Plify functions
        (Get-Item -Path Function:\*Plify*).Count | Should -BeGreaterThan 2

        # make sure we have our globals
        $ds | Should -be -not $null
        $plifyDevRoot | Should -be -not $null
        $plifyRoot | Should -be -not $null
        $plifyModuleRoot  | Should -be -not $null
        $PlifyModuleAliases | Should -be -not $null
        $PlifyActionMapping | Should -be -not $null
    }
}