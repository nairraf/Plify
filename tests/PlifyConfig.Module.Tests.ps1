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

Describe 'Initialize-PlifyConfig' {
    BeforeAll {
        $sep = [system.io.Path]::DirectorySeparatorChar
        $temp = (Get-Item $env:Temp).FullName
        $localPlifyConfigDir = "$temp$($sep)PlifyLocal"
        $globalPlifyConfigDir = "$temp$($sep)PlifyGlobal"
        Mock Get-PlifyConfigDir { return $localPlifyConfigDir } -ParameterFilter { $Scope -eq 'local' } -ModuleName PlifyConfig
        Mock Get-PlifyConfigDir { return $globalPlifyConfigDir } -ParameterFilter { $Scope -eq 'Global' } -ModuleName PlifyConfig
    }

    It 'Configures global directory when Scope=Global' {
        if ( (Test-Path -Path "$globalPlifyConfigDir") -eq $true) { Remove-Item -Path $globalPlifyConfigDir -Recurse -Force}
        Test-Path -Path $globalPlifyConfigDir | Should -Be $false
        Initialize-PlifyConfig -Scope Global
        Test-Path -Path $globalPlifyConfigDir | Should -Be $true
    }

    It 'Configures local directory when Scope=Local' {
        if ( (Test-Path -Path "$localPlifyConfigDir") -eq $true) { Remove-Item -Path $localPlifyConfigDir -Recurse -Force}
        Test-Path -Path $localPlifyConfigDir | Should -Be $false
        Initialize-PlifyConfig -Scope local
        Test-Path -Path $localPlifyConfigDir | Should -Be $true
    }
}

Describe 'Get-PlifyConfigDir' {
    It 'Should Return <Directory> When Passed <Scope>' {
        $localAppData = (Get-Item $env:LOCALAPPDATA).FullName
        (Get-PlifyConfigDir -Scope Local).StartsWith($localAppData) | Should -Be $false
        (Get-PlifyConfigDir -Scope Global).StartsWith($localAppData) | Should -Be $true
    }
}