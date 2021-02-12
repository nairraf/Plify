function Script:Write-TableDataToConsole() {
    param (
        [Parameter(Mandatory=$true)] [hashtable] $TableData,
        [Parameter(Mandatory=$true)] [array] $ColumnStartIndexes,
        [Parameter(Mandatory=$true)] [string] $HeaderLine,
        [Parameter(Mandatory=$true)] [string] $HeaderColor
    )

    # display the header - already properly spaced from the header function
    $ogForeground = [console]::ForegroundColor
    [console]::ForegroundColor = $HeaderColor
    Write-Output $HeaderLine
    [console]::ForegroundColor = $ogForeground

    # we figure out the column spacing in the header functions
    # the header function (Format-PlifyConsole*) then pass the ColumnStartIndexes
    # we simple align the data columns with the header Columns to write all the rows

    $numRows = $TableData.Rows.Count

    # print out the data organized by columns
    for ($r=0; $r -lt $numRows; $r++) {
        $rowLine = "" 
        for ($c=0; $c -lt $numColumns; $c++) {
            $columnData = ""
            $curLineLength = $rowline.Length
            while ($curLineLength -lt $ColumnStartIndexes[$c]-1) {
                $columnData += " "
                $curLineLength += 1
            }
            $columnData += " $($TableData.Rows[$r][$c])"
            #while ($columnData.Length -lt $columnMaxWidth) {
            #    $columnData += " "
            #}
            $rowline += $columnData
        }
        Write-Output $rowLine
    }
}

function Script:Format-PlifyConsoleAuto() {
    param(
        [Parameter(Mandatory=$true)] [hashtable] $TableData,
        [Parameter(Mandatory=$true)] [string] $HeaderColor
    )

    $width = [console]::WindowWidth
    $numColumns = $TableData.Headers.Count
    # the max size per screen with some padding
    $columnMaxWidth = ([math]::Floor($width/$numColumns) - 10)

    # figure out the largest string per column
    # we use this number to figure out the sizes of each column

    $columnSizes = @(0..($numColumns-1))
    
    # start with the header titles
    for ($c=0;$c -lt $numColumns; $c++) {
        if ($TableData.Headers[$c].Length -gt $columnSizes[$c]) {
            $columnSizes[$c] = $TableData.Headers[$c].Length
        }
    }

    # loop the data rows and look for the longest string per column
    for ($r=0;$r -lt $TableData.Rows.Count; $r++) {
        for ($c=0;$c -lt $numColumns; $c++) {
            if ($TableData.Rows[$r][$c].Length -gt $columnSizes[$c]) {
                $columnSizes[$c] = $TableData.Rows[$r][$c].Length
            }
        }
    }

    $padding = 2
    
    $headerLine = ""
    # holds the actual index of where we started the columns
    $columnStartIndexes = @(0..($numColumns-1)) 

    # figure out the column start locations and print out the table header row
    for ($c=0; $c -lt $numColumns; $c++) {
        # the first line start $padding spaces in
        if ($c -eq 0) { 
            $columnStartIndexes[$c] = $padding
        } else {
            $columnStartIndexes[$c] = $headerLine.Length + $padding
        }
        # pre-padd the line, add the header, and post-padd the line
        while ($headerLine.Length -lt $columnStartIndexes[$c]) {
            $headerLine += " "
        }

        # get the current header length so we know how many spaces
        # to right padd the line, to setup the next column properly
        $colLength = $TableData.Headers[$c].Length
        $headerLine += $TableData.Headers[$c]
        # pre-padd the line, add the header, and post-padd the line
        while ($colLength -lt $columnSizes[$c]) {
            $headerLine += " "
            $colLength += 1
        }
    }

    Write-TableDataToConsole -TableData $TableData -ColumnStartIndexes $columnStartIndexes -HeaderLine $headerLine -HeaderColor $HeaderColor
}

function Script:Format-PlifyConsoleLeft() {
    param(
        [Parameter(Mandatory=$true)] [hashtable] $TableData,
        [Parameter(Mandatory=$true)] [string] $HeaderColor
    )

    $width = [console]::WindowWidth
    $numColumns = $TableData.Headers.Count
    # the max size per screen with some padding
    $columnMaxWidth = ([math]::Floor($width/$numColumns) - 10)

    $headerLine = ""
    # holds the actual index of where we started the columns
    $columnStartIndexes = @(0..($numColumns-1)) 

    # figure out the column start locations and print out the table header row
    for ($c=0; $c -lt $numColumns; $c++) {
        # the first line start 4 spaces in
        if ($c -eq 0) { 
            $columnStartIndexes[$c] = 4
        } else {
            $columnStartIndexes[$c] = $columnStartIndexes[$c-1] + $columnMaxWidth
        }
        # padd the line
        while ($headerLine.Length -lt $columnStartIndexes[$c]) {
            $headerLine += " "
        }
        $headerLine += $TableData.Headers[$c]
    }

    Write-TableDataToConsole -TableData $TableData -ColumnStartIndexes $columnStartIndexes -HeaderLine $headerLine -HeaderColor $HeaderColor

}

function Script:Format-PlifyConsoleCenter() {
    param(
        [Parameter(Mandatory=$true)] [hashtable] $TableData,
        [Parameter(Mandatory=$true)] [string] $HeaderColor
    )

    $width = [console]::WindowWidth
    $numColumns = $TableData.Headers.Count
    # the max size per screen with some padding
    $columnMaxWidth = ([math]::Floor($width/$numColumns)-10)

    # Compute all the column center indexes
    $columnCenters = @(0..($numColumns-1))
    
    for ($c=0;$c -lt $numColumns; $c++) {
        if ($c -eq 0) { 
            # first column start at half column length
            $columnCenters[$c] = [math]::Floor($columnMaxWidth/2)
        } else {
            # add columnMaxWidth to the previous column index
            # to find the center for the current column
            $columnCenters[$c] = $columnCenters[$c-1]+$columnMaxWidth
        }
    }

    $headerLine = ""
    # holds the actual index of where we started the columns
    $columnStartIndexes = @(0..($numColumns-1)) 

    # figure out the column start locations and print out the table header row
    for ($c=0; $c -lt $numColumns; $c++) {
        #$headerLength = $TableData.Headers[$c].Length
        # center the header as much as we can based on the first column center index
        $columnStartIndexes[$c] = $columnCenters[$c] - [math]::Floor($headerLength/2)
        
        # padd the line
        while ($headerLine.Length -lt $columnStartIndexes[$c]) {
            $headerLine += " "
        }
        $headerLine += $TableData.Headers[$c]
    }

    Write-TableDataToConsole -TableData $TableData -ColumnStartIndexes $columnStartIndexes -HeaderLine $headerLine -HeaderColor $HeaderColor
}


<#
.SYNOPSIS
Display data tables on the console

.DESCRIPTION
Takes arrays of headers and data and figures out how to best 
display that data on the current console window

.PARAMETER HeaderColor
Default Green. what color the headers should be in the console


.PARAMETER TableData
a hastable of arrays containing the desired headers and data to display.
Example:
    $TableData = @{
        Headers = @('Column 1 Header', 'Column 2 Header', 'Column 3 Header')
        Rows = @()
    }

    $TableData.Rows += , ('DataRow1Column1', 'DataRow1Column2', 'DataRow1Column3')
    $TableData.Rows += , ('DataRow2Column1', 'DataRow2Column2', 'DataRow2Column3')
    $TableData.Rows += , ('DataRow3Column1', 'DataRow3Column2', 'DataRow3olumn3')

    Note: to keep powershell from flatening the array, when looping to add elements to $TableData.Rows 
          make sure to start the line with a comma (,) like so:
            $TableData.Rows += , 
          the comma forces powershell to treat the rest of the line (which should be surrounded in brackets) as a single element
          as per the 'DataRow#Column#' example above.

          If you do something like this without the initial comma:
            $TableData.Rows += @('DataRow1Column1', 'DataRow1Column2', 'DataRow1Column3')
          then this is actually just concatenating the elements onto the end of the existing array
          which just gives you a longer single dimension array. it would be the equivalent of:
            $TableData.Rows += 'DataRow1Column1'
            $TableData.Rows += 'DataRow1Column2'
            $TableData.Rows += 'DataRow1Column3'
#>
function Global:Write-PlifyConsole() {
    param(
        [Parameter(Mandatory=$false)] [string] $HeaderColor = "Green",
        [Parameter(Mandatory=$true)] [hashtable] $TableData,
        [Parameter(Mandatory=$false)] [string] $Format = "Auto"
    )

    if ($TableData.Count -eq 0 -or 
        ( $TableData.Keys -contains "Headers" -eq $false ) -or
        ( $TableData.Keys -contains "Rows" -eq $false ) ) {
        Write-Output "Invalid TableData hashtable detected..exiting"
        return
    }

    $formatters = @{
        Auto="Format-PlifyConsoleAuto"
        Left="Format-PlifyConsoleLeft"
        Center="Format-PlifyConsoleCenter"
    }

    if (-not ($formatters.keys -contains $Format)) {
        Write-Output "PlifyConsole: Unknown Formatter: $Format"
        return
    }

    Write-Output ""
    
    & $formatters.$Format -TableData $TableData -HeaderColor $HeaderColor

    Write-Output ""
}