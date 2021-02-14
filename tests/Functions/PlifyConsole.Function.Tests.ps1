#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
BeforeAll {
    . $PSSCriptRoot\..\beforeAll.ps1
}

Describe 'Plify Console Formatters' {
    BeforeAll {
        $TableData = @{
            Headers = @("Column1", "Column2", "Column3")
            Rows = @(
                , @("DataRow1Column1", "DataRow1Column2","DataRow1Column3"),
                , @("DataRow2Column1", "DataRow2Column2","DataRow2Column3"),
                , @("DataRow3Column1", "DataRow3Column2","DataRow3Column3"),
                , @("DataRow4Column1", "DataRow4Column2","DataRow4Column3"),
                , @("DataRow5Column1", "DataRow5Column2","DataRow5Column3")
            )
        }
    }
    It 'Should Display the left formatter' {
        $output = Write-PlifyConsole -TableData $TableData -Format "Left" -HeaderColor "Red"

        $output[1] | Should -BeLike "*Column1*Column2*Column3"
        $output[2] | Should -BeLike "*DataRow1Column1*DataRow1Column2*DataRow1Column3*"
        $output[3] | Should -BeLike "*DataRow2Column1*DataRow2Column2*DataRow2Column3*"
        $output[4] | Should -BeLike "*DataRow3Column1*DataRow3Column2*DataRow3Column3*"
        $output[5] | Should -BeLike "*DataRow4Column1*DataRow4Column2*DataRow4Column3*"
        $output[6] | Should -BeLike "*DataRow5Column1*DataRow5Column2*DataRow5Column3*"
    }
    It 'Should Display the center formatter' {
        $output = Write-PlifyConsole -TableData $TableData -Format "Center"

        $output[1] | Should -BeLike "*Column1*Column2*Column3"
        $output[2] | Should -BeLike "*DataRow1Column1*DataRow1Column2*DataRow1Column3*"
        $output[3] | Should -BeLike "*DataRow2Column1*DataRow2Column2*DataRow2Column3*"
        $output[4] | Should -BeLike "*DataRow3Column1*DataRow3Column2*DataRow3Column3*"
        $output[5] | Should -BeLike "*DataRow4Column1*DataRow4Column2*DataRow4Column3*"
        $output[6] | Should -BeLike "*DataRow5Column1*DataRow5Column2*DataRow5Column3*"
    }
    It 'Should Display the auto formatter' {
        $output = Write-PlifyConsole -TableData $TableData -Format "Auto"

        $output[1] | Should -BeLike "*Column1*Column2*Column3"
        $output[2] | Should -BeLike "*DataRow1Column1*DataRow1Column2*DataRow1Column3*"
        $output[3] | Should -BeLike "*DataRow2Column1*DataRow2Column2*DataRow2Column3*"
        $output[4] | Should -BeLike "*DataRow3Column1*DataRow3Column2*DataRow3Column3*"
        $output[5] | Should -BeLike "*DataRow4Column1*DataRow4Column2*DataRow4Column3*"
        $output[6] | Should -BeLike "*DataRow5Column1*DataRow5Column2*DataRow5Column3*"
    }

    It 'Should Display the auto formatter by default' {
        $output = Write-PlifyConsole -TableData $TableData

        $output[1] | Should -BeLike "*Column1*Column2*Column3"
        $output[2] | Should -BeLike "*DataRow1Column1*DataRow1Column2*DataRow1Column3*"
        $output[3] | Should -BeLike "*DataRow2Column1*DataRow2Column2*DataRow2Column3*"
        $output[4] | Should -BeLike "*DataRow3Column1*DataRow3Column2*DataRow3Column3*"
        $output[5] | Should -BeLike "*DataRow4Column1*DataRow4Column2*DataRow4Column3*"
        $output[6] | Should -BeLike "*DataRow5Column1*DataRow5Column2*DataRow5Column3*"
    }
}

