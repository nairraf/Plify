#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
BeforeAll {
    . $PSSCriptRoot\..\beforeAll.ps1
}

Describe "Get-PlifyRepository" {
    BeforeEach {
        $temp = (Get-Item $env:Temp).FullName
        $localPlifyConfigDir = "$temp$($ds)PlifyLocal"
        $globalPlifyConfigDir = "$temp$($ds)PlifyGlobal"
        if (Test-Path -Path "$localPlifyConfigDir") { Remove-Item -Path $localPlifyConfigDir -Recurse -Force }
        if (Test-Path -Path "$globalPlifyConfigDir") { Remove-Item -Path $globalPlifyConfigDir -Recurse -Force }
        Mock Get-PlifyConfigurationDir { return $localPlifyConfigDir } -ParameterFilter { $Scope -eq 'local' } -ModuleName PlifyConfiguration
        Mock Get-PlifyConfigurationDir { return $globalPlifyConfigDir } -ParameterFilter { $Scope -eq 'Global' } -ModuleName PlifyConfiguration
        Initialize-PlifyConfiguration -Scope Global
    }

    AfterEach {
        if (Test-Path -Path "$localPlifyConfigDir") { Remove-Item -Path $localPlifyConfigDir -Recurse -Force }
        if (Test-Path -Path "$globalPlifyConfigDir") { Remove-Item -Path $globalPlifyConfigDir -Recurse -Force }
    }

    It "Should list two repositories by default - formatted" {
        $output = Plifyrepository\Get-PlifyRepository
        $output.Count | Should -Be 2
    }
}

Describe 'New-PlifyRepository' {
    BeforeEach {
        $temp = (Get-Item $env:Temp).FullName
        $localPlifyConfigDir = "$temp$($ds)PlifyLocal"
        $globalPlifyConfigDir = "$temp$($ds)PlifyGlobal"
        if (Test-Path -Path "$localPlifyConfigDir") { Remove-Item -Path $localPlifyConfigDir -Recurse -Force }
        if (Test-Path -Path "$globalPlifyConfigDir") { Remove-Item -Path $globalPlifyConfigDir -Recurse -Force }
        Mock Get-PlifyConfigurationDir { return $localPlifyConfigDir } -ParameterFilter { $Scope -eq 'local' } -ModuleName PlifyConfiguration
        Mock Get-PlifyConfigurationDir { return $globalPlifyConfigDir } -ParameterFilter { $Scope -eq 'Global' } -ModuleName PlifyConfiguration
        Initialize-PlifyConfiguration -Scope Global
    }

    AfterEach {
        if (Test-Path -Path "$localPlifyConfigDir") { Remove-Item -Path $localPlifyConfigDir -Recurse -Force }
        if (Test-Path -Path "$globalPlifyConfigDir") { Remove-Item -Path $globalPlifyConfigDir -Recurse -Force }
    }

    It 'Should Add a new Repository' {
        $options = @{
            Name = "Test Repository"
            Enabled = $true
            Description = "Plify Test Repository"
            URL = "https://testrepo.plify.xyz"
        }
        PlifyRepository\New-PlifyRepository @options
        $repos = PlifyRepository\Get-PlifyRepository
        $repos.count | Should -Be 3
        $repos.Name | Should -Contain "Test Repository"
    }

    It 'Should be disabled by default' {
        $options = @{
            Name = "Test Repository"
            Description = "Plify Test Repository"
            URL = "https://testrepo.plify.xyz"
        }
        PlifyRepository\New-PlifyRepository @options
        $repos = PlifyRepository\Get-PlifyRepository
        $repos.count | Should -Be 3
        $repos.Name | Should -Contain "Test Repository"
        ($repos | Where-Object { $_.name -eq "Test Repository"}).Enabled | Should -Be $false
    }
}