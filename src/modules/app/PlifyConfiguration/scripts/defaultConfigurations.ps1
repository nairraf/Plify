$defaultPlifyConfigGlobal = @{
    Repositories = @{ 
        'PlifyDev' = @{
            url='devrepo.plify.xyz'
            enabled=$false
            name='Official Dev Plify Repository'
        }
        'PlifyProd' = @{
            url='repo.plify.xyz'
            enabled=$true
            name='Official Production Plify Repository'
        }
    }
}