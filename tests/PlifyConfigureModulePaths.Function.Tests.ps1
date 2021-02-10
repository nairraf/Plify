#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
BeforeAll {
    . $PSSCriptRoot\beforeAll.ps1
}

Describe 'Set-PlifyModuleRoots' {
    BeforeEach {
        # make sure that the PSModulePath does NOT contain plify module roots
        Remove-PlifyModuleRoots
    }

    it 'Should Set Module Path Correctly' {
        $envPathBefore = $env:PSModulePath
        $envPathBefore.Contains("Plify$($ds)src$($ds)modules$($ds)app") | Should -Be $false
        $envPathBefore.Contains("Plify$($ds)src$($ds)modules$($ds)core") | Should -Be $false
        $envPathBefore.Contains("Plify$($ds)src$($ds)modules$($ds)managers") | Should -Be $false
           
        Set-PlifyModuleRoots
        $envPathAfter = $env:PSModulePath
        $envPathAfter.Contains("Plify$($ds)src$($ds)modules$($ds)app") | Should -Be $true
        $envPathAfter.Contains("Plify$($ds)src$($ds)modules$($ds)core") | Should -Be $true
        $envPathAfter.Contains("Plify$($ds)src$($ds)modules$($ds)managers") | Should -Be $true
    }
}

Describe 'Remove-PlifyModuleRoots' {
    BeforeEach {
        # make sure that the PSModulePath does NOT contain plify module roots
        Set-PlifyModuleRoots
    }

    it 'Should Remove Plify Module Roots Correctly' {
        $envPathBefore = $env:PSModulePath
        $envPathBefore.Contains("Plify$($ds)src$($ds)modules$($ds)app") | Should -Be $true
        $envPathBefore.Contains("Plify$($ds)src$($ds)modules$($ds)core") | Should -Be $true
        $envPathBefore.Contains("Plify$($ds)src$($ds)modules$($ds)managers") | Should -Be $true
           
        Remove-PlifyModuleRoots
        $envPathAfter = $env:PSModulePath
        $envPathAfter.Contains("Plify$($ds)src$($ds)modules$($ds)app") | Should -Be $false
        $envPathAfter.Contains("Plify$($ds)src$($ds)modules$($ds)core") | Should -Be $false
        $envPathAfter.Contains("Plify$($ds)src$($ds)modules$($ds)managers") | Should -Be $false
    }
    
}