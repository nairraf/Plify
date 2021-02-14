#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
BeforeAll {
    . $PSSCriptRoot\..\beforeAll.ps1
}

Describe 'Get-PlifyHelp' {
    it "Returns Default Help" {
        $helpText = PlifyHelp\Get-PlifyHelp 
        $helpText | should -Contain "overview"
        $helpText | should -Contain "usage"
        $helpText | should -Contain "module specific help"
        $helpText | should -Contain "Available Modules : Module Aliases"
    }
}