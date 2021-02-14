$defaultPlifyConfigGlobal = @{
    Repositories = @{ 
        'PlifyDev' = @{
            url='devrepo.plify.xyz'
            enabled=$false
            description='Official Dev Plify Repository'
        }
        'PlifyProd' = @{
            url='repo.plify.xyz'
            enabled=$true
            description='Official Production Plify Repository'
        }
    }
}