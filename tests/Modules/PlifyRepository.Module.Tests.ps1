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
        Import-Module PlifyRepository
        Mock Get-PlifyConfigurationDir { return $globalPlifyConfigDir } -ParameterFilter { $Scope -eq 'Global' } -ModuleName PlifyRepository
        Initialize-PlifyConfiguration -Scope Global

        $pfxArchive = "$temp$($ds)Test.pfx"
        if (Test-Path -Path $pfxArchive) {
            Remove-Item -Path $pfxArchive
        }
    }

    AfterEach {
        if (Test-Path -Path "$localPlifyConfigDir") { Remove-Item -Path $localPlifyConfigDir -Recurse -Force }
        if (Test-Path -Path "$globalPlifyConfigDir") { Remove-Item -Path $globalPlifyConfigDir -Recurse -Force }
        $pfxArchive = "$temp$($ds)Test.pfx"
        if (Test-Path -Path $pfxArchive) {
            Remove-Item -Path $pfxArchive
        }
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
            Thumbprint = "1a3b3c4d"
        }
        PlifyRepository\New-PlifyRepository @options
        $repos = PlifyRepository\Get-PlifyRepository
        $repos.count | Should -Be 3
        $repos.Name | Should -Contain "Test Repository"
        $testrepo = $repos | Where-Object { $_.Name -eq "Test Repository" }
        $testrepo.Enabled | Should -BeTrue
        $testrepo.Description | Should -Be "Plify Test Repository"
        $testrepo.URL | Should -Be "https://testrepo.plify.xyz"
        $testrepo.Thumbprint | Should -Be "1a3b3c4d"
    }

    It 'New-PlifyRepository Should be disabled by default' {
        $options = @{
            Name = "Test Repository"
            Description = "Plify Test Repository"
            URL = "https://testrepo.plify.xyz"
            Thumbprint = "1a3b3c4d"
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

    it 'Update-PlifyRepository Should update a specific repo' {
        # the dev repo should not be enabled by default
        (PlifyRepository\Get-PlifyRepository -Name "PlifyDev").Enabled | Should -Be $false

        # enable it and test
        PlifyRepository\Update-PlifyRepository -Name 'PlifyDev' -Enabled $true
        (PlifyRepository\Get-PlifyRepository -Name "PlifyDev").Enabled | Should -Be $true

         # disable it and test
         PlifyRepository\Update-PlifyRepository -Name 'PlifyDev' -Enabled $false
         (PlifyRepository\Get-PlifyRepository -Name "PlifyDev").Enabled | Should -Be $false

        # change the description and test
        PlifyRepository\Update-PlifyRepository -Name 'PlifyDev' -Description "Test Description"
        (PlifyRepository\Get-PlifyRepository -Name "PlifyDev").Description | Should -Be "Test Description"

        # change the URL and test
        PlifyRepository\Update-PlifyRepository -Name 'PlifyDev' -URL "https://Test.URL"
        (PlifyRepository\Get-PlifyRepository -Name "PlifyDev").URL | Should -Be "https://Test.URL"

        # change the thumbprint and test
        PlifyRepository\Update-PlifyRepository -Name 'PlifyDev' -Thumbprint "1a2b3c4d"
        (PlifyRepository\Get-PlifyRepository -Name "PlifyDev").Thumbprint | Should -Be "1a2b3c4d"

        # change the repo name and test
        PlifyRepository\Update-PlifyRepository -Name 'PlifyDev' -NewName "PlifyTest"
        (PlifyRepository\Get-PlifyRepository -Name "PlifyTest").Name | Should -Be "PlifyTest"

        # change everything
        $options = @{
            Name = "PlifyTest"
            NewName = "PlifyDev"
            Enabled = $false
            Description = "Official Dev Plify Repository"
            URL = "https://devrepo.plify.xyz"
            Thumbprint = "1a2b3c4d1a2b3c4d"
        }
        PlifyRepository\Update-PlifyRepository @options
        (PlifyRepository\Get-PlifyRepository -Name "PlifyDev").Name | Should -Be "PlifyDev"
        (PlifyRepository\Get-PlifyRepository -Name "PlifyDev").Enabled | Should -Be $false
        (PlifyRepository\Get-PlifyRepository -Name "PlifyDev").Description | Should -Be "Official Dev Plify Repository"
        (PlifyRepository\Get-PlifyRepository -Name "PlifyDev").URL | Should -Be "https://devrepo.plify.xyz"
        (PlifyRepository\Get-PlifyRepository -Name "PlifyDev").Thumbprint | Should -Be "1a2b3c4d1a2b3c4d"
    }

    It 'Sync-PlifyRepository should successfully sync the dev repository' {
        # make sure the dev repo is enabled
        PlifyRepository\Update-PlifyRepository -Name "PlifyDev" -Enabled $true
        $repoCache = PlifyRepository\Get-PlifyRepositoryCacheFile
        Test-Path -Path $repoCache | Should -BeFalse
        PlifyRepository\Sync-PlifyRepository -Force
        Test-Path -Path $repoCache | Should -BeTrue
        $json = Get-Content -Path $repoCache -Raw | ConvertFrom-Json -Depth 5
        $json.PlifyDev.Count | Should -BeGreaterThan 0
    }

    It 'Get-PlifyRepositoryCertificateDir should return global certificate directory' {
        Get-PlifyRepositoryCertificateDir | Should -Be "$globalPlifyConfigDir$($ds)certificates"
    }

    It 'New-PlifyRepositoryCertificate should not generate a certificate if repository doesnt exist' {
        { PlifyRepository\New-PlifyRepositoryCertificate -Name "Test" } | Should -Throw
    }

    It 'New-PlifyRepositoryCertificate should not generate a certificate for default plify repositories' -ForEach @(
        @{ RepoName="PlifyProd"}
        @{ RepoName="PlifyDev"}
    ) {
        param ( $RepoName )
        { PlifyRepository\New-PlifyRepositoryCertificate -Name $RepoName } | Should -Throw
    }

    It 'New-PlifyRepositoryCertificate should generate a certificate' {
        PlifyRepository\New-PlifyRepository -Name "Test"
        PlifyRepository\New-PlifyRepositoryCertificate -Name "Test"
        $certDir = Get-PlifyRepositoryCertificateDir
        Test-Path -Path "$certDir$($ds)Test.key.private" | Should -BeTrue
        Test-Path -Path "$certDir$($ds)Test.key.public" | Should -BeTrue
        Test-Path -Path "$certDir$($ds)Test.crt" | Should -BeTrue
        $testRepo = PlifyRepository\Get-PlifyRepository -Name "Test"
        $testRepo.Thumbprint | Should -Not -BeNullOrEmpty
    }

    It 'Backup-PlifyRepositoryCertificate should not backup a cert if the file already exists' {
        # create a test repository and certificate
        # create a fake backup file, and make sure it's not overwritten by comparing modification dates and sizes
        PlifyRepository\New-PlifyRepository -Name "Test"
        PlifyRepository\New-PlifyRepositoryCertificate -Name "Test"
        $pfxArchive = "$temp$($ds)Test.pfx"
        New-Item -Path $pfxArchive -ItemType File
        { Backup-PlifyRepositoryCertificate -Name Test -Path $temp -Password "password" } | Should -Throw
    }

    It 'Backup-PlifyRepositoryCertificate should backup a cert if the file already exists with force' {
        # create a test repository and certificate
        # create a fake backup file, and make sure it's not overwritten by comparing modification dates and sizes
        PlifyRepository\New-PlifyRepository -Name "Test"
        PlifyRepository\New-PlifyRepositoryCertificate -Name "Test"
        New-Item -Path $pfxArchive -ItemType File
        $fakefile = Get-Item -Path $pfxArchive | Select-Object LastWriteTimeUtc,Length
        PlifyRepository\Backup-PlifyRepositoryCertificate -Name Test -Path $temp -Force -Password "password"
        $metaFile = (Get-Item -Path $pfxArchive | Select-Object LastWriteTimeUtc,Length)
        $metaFile.LastWriteTimeUtc | Should -BeGreaterThan $fakefile.LastWriteTimeUtc
        $metaFile.Length | Should -BeGreaterThan $fakefile.Length
    }

    It 'Backup-PlifyRepositoryCertificate should generate a pfx archive to a user specified location' {
        PlifyRepository\New-PlifyRepository -Name "Test"
        PlifyRepository\New-PlifyRepositoryCertificate -Name "Test"
        $pfxArchive = "$temp$($ds)Test.pfx"
        PlifyRepository\Backup-PlifyRepositoryCertificate -Name Test -Path $temp -Password "password"
        Test-Path -Path $pfxArchive | Should -BeTrue
    }

    It 'Restore-PlifyRepositoryCertificate should not restore certificate if one already exists' {
        PlifyRepository\New-PlifyRepository -Name "Test"
        PlifyRepository\New-PlifyRepositoryCertificate -Name "Test"
        $pfxArchive = "$temp$($ds)Test.pfx"
        PlifyRepository\Backup-PlifyRepositoryCertificate -Name Test -Path $temp -Password "password"
        { PlifyRepository\Restore-PlifyRepositoryCertificate -Name "Test" -Path $pfxArchive -Password "password" } | Should -Throw
    }

    It 'Restore-PlifyRepositoryCertificate should restore certificate if one already exists with force' {
        PlifyRepository\New-PlifyRepository -Name "Test"
        PlifyRepository\New-PlifyRepositoryCertificate -Name "Test"
        $pfxArchive = "$temp$($ds)Test.pfx"
        PlifyRepository\Backup-PlifyRepositoryCertificate -Name Test -Path $temp -Password "password"
        $privateKeyPre = Get-Item -Path "$globalPlifyConfigDir$($ds)certificates$($ds)Test.key.private"
        PlifyRepository\Restore-PlifyRepositoryCertificate -Name "Test" -Path $pfxArchive -Password "password" -Force
        $privateKeyPost = Get-Item -Path "$globalPlifyConfigDir$($ds)certificates$($ds)Test.key.private"
        $privateKeyPost.LastWriteTimeUtc | Should -BeGreaterThan $privateKeyPre.LastWriteTimeUtc
    }

    It 'Restore-PlifyRepositoryCertificate should not try and restore an invalid backup' {
        PlifyRepository\New-PlifyRepository -Name "Test"
        PlifyRepository\New-PlifyRepositoryCertificate -Name "Test"
        { PlifyRepository\Restore-PlifyRepositoryCertificate -Name "Test" -Path "bad\path" -Password "password" -Force } | Should -Throw "Invalid PFX Path*"
        { PlifyRepository\Restore-PlifyRepositoryCertificate -Name "Test" -Path "bad\path.pfx" -Password "password" -Force } | Should -Throw "Invalid PFX Path*"
    }
}