$defaultPlifyConfigGlobal = @{
    Repositories = @{ 
        'PlifyDev' = @{
            url='https://devrepo.plify.xyz'
            enabled=$false
            description='Official Dev Plify Repository'
        }
        'PlifyProd' = @{
            url='https://repo.plify.xyz'
            enabled=$true
            description='Official Production Plify Repository'
        }
    }
}