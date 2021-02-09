# returns a list of official translations
function Global:Get-PlifyOfficialTranslations() {
    return @('eng')
}

function Global:Get-PlifyTranslation() {
    $currentCultureISO = (Get-Culture).ThreeLetterISOLanguageName
    $translations = Get-PlifyOfficialTranslations
    if ( $translations -contains  $currentCultureISO ) {
        Write-Debug "Using Detected Translation: $currentCultureISO"
        return $currentCultureISO
    } else {
        Write-Debug "Using Default Translation"
        return 'eng'
    }
}
