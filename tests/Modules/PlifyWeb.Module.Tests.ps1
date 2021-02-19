#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
BeforeAll {
    . $PSSCriptRoot\..\beforeAll.ps1
}

Describe 'Get-PlifyWebContent' {
    It 'Should return text' {
        $url = "https://reqres.in/api/users/2"
        $content = PlifyWeb\Get-PlifyWebContent -Url $url
        $content | Should -Match "first_name"
    }
}

Describe 'Get-PlifyWebLargeFile()' {
    BeforeEach {
        $tmpFile = (Get-Item -Path $env:temp).FullName + $ds + "5MB.zip"
        $sha256 = "C0DE104C1E68625629646025D15A6129A2B4B6496CD9CEACD7F7B5078E1849BA"
        $url = "http://devrepo.plify.xyz/tests/5MB.zip"
        if (Test-Path -Path $tmpFile) {
            Remove-Item -Path $tmpFile -Force
        }
    }

    AfterEach {
        if (Test-Path -Path $tmpFile) {
            Remove-Item -Path $tmpFile -Force
        }
    }

    It 'Should download the 5MB file and return true' {
        $return = PlifyWeb\Get-PlifyWebLargeFile -Url $url -FilePath "$tmpFile" -sha256 $sha256
        $return | Should -BeTrue
    }

    It 'Should return false on invalid URL' {
        $return = PlifyWeb\Get-PlifyWebLargeFile -Url "http://bad.url/badfile.name" -FilePath $tmpFile
        $return | Should -BeFalse
    }

    It 'Should return true without a hash to compare if download file exists' {
        $return = PlifyWeb\Get-PlifyWebLargeFile -Url $url -FilePath $tmpFile
        $return | Should -BeTrue
    }
}