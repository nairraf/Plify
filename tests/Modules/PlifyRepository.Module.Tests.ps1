#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
BeforeAll {
    . $PSSCriptRoot\..\beforeAll.ps1
}

Describe 'PlifyRepository Management' {
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

    It "Get-PlifyRepository Should list two repositories by default" {
        $output = Plifyrepository\Get-PlifyRepository
        $output.Count | Should -Be 2
    }

    It "Get-PlifyRepository Should retrieve a repo by name" {
        $output = Plifyrepository\Get-PlifyRepository -Name "PlifyProd"
        $output.Count | Should -Be 1
    }

    It "Get-PlifyRepository Should retrieve a repos wildcard" {
        $output = Plifyrepository\Get-PlifyRepository -Name "Plify*"
        $output.Count | Should -Be 2

        $output = Plifyrepository\Get-PlifyRepository -Name "*Prod"
        $output.Count | Should -Be 1
    }

    It 'New-PlifyRepository Should Add a new Repository' {
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

    It 'New-PlifyRepository Should be disabled by default' {
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

    It 'Remove-PlifyRepository Should remove a Repository' {
        $repos = PlifyRepository\Get-PlifyRepository
        $repos.count | Should -Be 2
        
        PlifyRepository\Remove-PlifyRepository -Name "PlifyDev"
        $repos = PlifyRepository\Get-PlifyRepository
        $repos.count | Should -Be 1
        ($repos | Where-Object { $_.name -eq "PlifyProd"}).Count | Should -Be 1
        ($repos | Where-Object { $_.name -eq "PlifyDev"}).Count | Should -Be 0
    }

    It 'Remove-PlifyRepository Should remove repositories using wildcards' -ForEach @(
        @{ Pattern="*Dev"; Count=1; }
        @{ Pattern="*Prod"; Count=1 }
        @{ Pattern="Plify*"; Count=0 }
    ){
        param($Pattern, $Count)

        $repos = PlifyRepository\Get-PlifyRepository
        $repos.count | Should -Be 2
        
        PlifyRepository\Remove-PlifyRepository -Name $Pattern
        $repos = PlifyRepository\Get-PlifyRepository
        $repos.count | Should -Be $Count
    }

    It 'Remove-PlifyRepository Should not remove anything for an invalid Repository' {
        $repos = PlifyRepository\Get-PlifyRepository
        $repos.count | Should -Be 2
        
        PlifyRepository\Remove-PlifyRepository -Name "PlifyBadRepoName"
        $repos = PlifyRepository\Get-PlifyRepository
        $repos.count | Should -Be 2
        ($repos | Where-Object { $_.name -eq "PlifyProd"}).Count | Should -Be 1
        ($repos | Where-Object { $_.name -eq "PlifyDev"}).Count | Should -Be 1
    }
}