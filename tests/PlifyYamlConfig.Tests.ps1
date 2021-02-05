#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
BeforeAll {
    . $PSSCriptRoot\beforeAll.ps1
}

Describe "Get-PlifyYamlConfig" {
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
test
- test
      test
        - test
 test
  - test
'@
    }

    It "Returns Dictionary From Valid Yaml" {
        $tst = Get-PlifyYamlConfig -RawYaml $YAML
        $tst.Networks.Count | Should -Be 2
        $tst.VirtualMachines.Count | Should -Be 1
        $tst | Should -BeOfType [hashtable]
    }

    It "Returns nothing from bad Yaml" {
        $tst = Get-PlifyYamlConfig -RawYaml $YamlBad
        $tst | Should -Be $null
    }

    It "Returns nothing from root only" {
        $tst = Get-PlifyYamlConfig -RawYaml $YamlOnlyRoot
        $tst | Should -Be $null
    }

    It "Returns nothing from no root" {
        $tst = Get-PlifyYamlConfig -RawYaml $YamlNoRoot
        $tst | Should -Be $null
    }
}