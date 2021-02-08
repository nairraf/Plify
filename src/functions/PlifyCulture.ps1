# returns a list of official translations
function Global:Get-PlifyTranslations() {
    return @('eng')
}

function Global:Get-PlifyTranslation() {
    $currentCultureISO = (Get-Culture).ThreeLetterISOLanguageName
    if ( Get-PlifyTranslations -Contains  $currentCultureISO ) {
        Write-Debug "Using Detected Translation: $currentCultureISO"
        return $currentCultureISO
    } else {
        Write-Debug "Using Default Translation"
        return 'eng'
    }
}
