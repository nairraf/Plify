#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
BeforeAll {
    . $PSSCriptRoot\beforeAll.ps1
}

Describe "Get-PlifyConfigFromYaml" {
    BeforeAll {
        $YAML = @'
- RootDirectory: .plify
- Networks:
    - Test Switch:
    - type: Internal|Private
- VirtualMachines:
    - TestVM1:
        - group: Test Group 1
        - vcpu:
            - number: 2
        - memory: 
            - size: 2GB
            - dynamic:
            - min: 512MB
            - max: 2GB
            - buffer_percent: 10
            - weight: 5
        - networks: 
            - nic01:
                - switch: Test Switch
                - vlan_enabled: True
                - vlan_id: 200
            - nic02:
                - switch: Test Switch
                - vlan_enabled: True
                - vlan_id: 201
        - disks:
            - disk01:
                - type: Fixed|Dynamic|Differencing|Copy
                - vhd_format: vhd|vhdx
                - name: testvm1_root
                - base_image_name: Some Image
            - disk02:
                - type: Dynamic
                - vhd_format: vhdx
                - name: testvm1_home
                - size: 20GB
        - generation: 2
        - secureboot:
            - enabled: True
            - Template: Microsoft Windows|MS UEFI CA|OS Sheilded VM
        - checkpoints:
            - enabled: True
            - automatic: False
            - type: Standard|Production
        - automatic_actions:
            - start:
            - action: Nothing|Automatic|Always
            - delay_seconds: 2
            - stop: Save|Turn Off|Shut Down        
'@

        $YamlNoRoot = @'
- Networks:
    - Test Switch:
    - type: Internal|Private
- VirtualMachines:
    - TestVM1:
'@

        $YamlOnlyRoot = @'
- RootDirectory: .plify 
'@

        $YamlBad = @'
- test:
        invalid: yaml
        more: invalid yaml
        and: some more
'@
    }

    It "Returns Dictionary From Valid Yaml" {
        $tst = Get-PlifyConfigFromYaml -RawYaml $YAML
        $tst.Networks.Count | Should -Be 2
        $tst.VirtualMachines.Count | Should -Be 1
        $tst | Should -BeOfType [hashtable]
    }

    It "Returns nothing from bad Yaml" {
        $tst = Get-PlifyConfigFromYaml -RawYaml $YamlBad
        $tst | Should -Be $null
    }

    It "Returns nothing from root only" {
        $tst = Get-PlifyConfigFromYaml -RawYaml $YamlOnlyRoot
        $tst | Should -Be $null
    }

    It "Returns nothing from no root" {
        $tst = Get-PlifyConfigFromYaml -RawYaml $YamlNoRoot
        $tst | Should -Be $null
    }
}

Describe 'Initialize|Get|Set PlifyConfig' {
    BeforeEach {
        $temp = (Get-Item $env:Temp).FullName
        $localPlifyConfigDir = "$temp$($ds)PlifyLocal"
        $globalPlifyConfigDir = "$temp$($ds)PlifyGlobal"
        if (Test-Path -Path "$localPlifyConfigDir") { Remove-Item -Path $localPlifyConfigDir -Recurse -Force }
        if (Test-Path -Path "$globalPlifyConfigDir") { Remove-Item -Path $globalPlifyConfigDir -Recurse -Force }
        Mock Get-PlifyConfigDir { return $localPlifyConfigDir } -ParameterFilter { $Scope -eq 'local' } -ModuleName PlifyConfig
        Mock Get-PlifyConfigDir { return $globalPlifyConfigDir } -ParameterFilter { $Scope -eq 'Global' } -ModuleName PlifyConfig
    }

    AfterEach {
        if (Test-Path -Path "$localPlifyConfigDir") { Remove-Item -Path $localPlifyConfigDir -Recurse -Force }
        if (Test-Path -Path "$globalPlifyConfigDir") { Remove-Item -Path $globalPlifyConfigDir -Recurse -Force }
    }

    It 'Configures global directory when Scope=Global' {
        Test-Path -Path $globalPlifyConfigDir | Should -Be $false
        Initialize-PlifyConfig -Scope Global
        Test-Path -Path $globalPlifyConfigDir | Should -Be $true
    }

    It 'Configures local directory when Scope=Local' {
        Test-Path -Path $localPlifyConfigDir | Should -Be $false
        Initialize-PlifyConfig -Scope local
        Test-Path -Path $localPlifyConfigDir | Should -Be $true
    }

    It 'Should create default global configuration' {
        Initialize-PlifyConfig -Scope Global
        Test-Path -Path "$globalPlifyConfigDir$($ds)config.yml" | Should -Be $true
    }

    It 'Should Retrieve Local Plify Config' {
        # Todo
    }

    It 'Should Retrieve Global Plify Config as string' {
        Initialize-PlifyConfig -Scope Global
        (Get-PlifyConfig -Scope "Global") -match 'repositories:*' | Should -Be $true
        (Get-PlifyConfig -Scope "Global").GetType().Name | Should -Be "String"
    }

    It 'Should Retrieve Global Plify Config as PS Types' {
        Initialize-PlifyConfig -Scope Global
        (Get-PlifyConfig -Scope "Global" -ConvertToPS).Keys | Should -Contain "Repositories"
        (Get-PlifyConfig -Scope "Global" -ConvertToPS).GetType().Name | Should -Be "Hashtable"
    }

    It 'Should Add a "Test" key/value to the global Plify Config' {
        Initialize-PlifyConfig -Scope Global
        $config = Get-PlifyConfig -Scope "Global" -ConvertToPS
        $config["Test"] = @{}
        $config["Test"]["key"] = "test value"

        Set-PlifyGlobalConfig -Config $config

        (Get-PlifyConfig -Scope "Global" -ConvertToPS).Keys | Should -Contain "Test"
        (Get-PlifyConfig -Scope "Global" -ConvertToPS)["Test"]["key"] | Should -Be "test value"
    }

    It 'Should Modify only the "Test" key/value in the global Plify Config' {
        Initialize-PlifyConfig -Scope Global
        $config = Get-PlifyConfig -Scope "Global" -ConvertToPS
        $config["Test"] = @{Key="New Value"; NewKey="Edit Test"}

        Set-PlifyGlobalConfig -Config $config

        (Get-PlifyConfig -Scope "Global" -ConvertToPS).Keys | Should -Contain "Repositories"
        (Get-PlifyConfig -Scope "Global" -ConvertToPS).Keys | Should -Contain "Test"
        (Get-PlifyConfig -Scope "Global" -ConvertToPS)["Test"]["key"] | Should -Be "New Value"
        (Get-PlifyConfig -Scope "Global" -ConvertToPS)["Test"]["NewKey"] | Should -Be "Edit Test"
    }

    It 'Should retrieve and update only the "Test" Global config element' {
        Initialize-PlifyConfig -Scope Global

        # create and save a test config key
        $config = Get-PlifyConfig -Scope "Global" -ConvertToPS
        $config["Test"] = @{Key="New Value"; NewKey="Edit Test"}
        Set-PlifyGlobalConfig -Config $config

        # reload our $config variable to pull in just the Test element
        $config = Get-PlifyConfig -Scope "Global" -ConvertToPS -RootElement "Test"
        $config.Keys | Should -Not -Contain "Repositories"
        $config.Keys | Should -Contain "Test"

        # update the test element
        $config["Test"] = @{Key="Test 3"; NewKey="Edit Test 3"}

        # save just the Test element to global config
        # this should only overwrite the Test element
        Set-PlifyGlobalConfig -Config $config -RootElement "Test"

        # refresh our config and make sure it contains the complete config (default config + our changes)
        $config = Get-PlifyConfig -Scope "Global" -ConvertToPS

        $config.Keys | Should -Contain "Repositories"
        $config.Keys | Should -Contain "Test"
        $config["Test"]["Key"] | Should -Be "Test 3"
        $config["Test"]["NewKey"] | Should -Be "Edit Test 3"
    }
}

Describe 'Get-PlifyConfigDir' {
    It 'Should Configure local and global properly' {
        $localAppData = (Get-Item $env:LOCALAPPDATA).FullName
        (Get-PlifyConfigDir -Scope Local).StartsWith($localAppData) | Should -Be $false
        (Get-PlifyConfigDir -Scope Global).StartsWith($localAppData) | Should -Be $true
    }

    It 'Should Return Correct Plify dir names' -Foreach @(
        @{ DirName="test" }
    ){
        param ($DirName)
        (Get-PlifyConfigDir -DirName $DirName).EndsWith(".$($DirName)") | Should -Be $true
    }

    It 'Should Return Default local Plify dir name' {
        param ($DirName)
        (Get-PlifyConfigDir).EndsWith(".Plify") | Should -Be $true
    }
}