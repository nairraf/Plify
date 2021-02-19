$defaultPlifyConfigGlobal = @{
    Repositories = @{ 
        'PlifyDev' = @{
            url='https://devrepo.plify.xyz'
            enabled=$false
            description='Official Dev Plify Repository'
            thumbprint=""
        }
        'PlifyProd' = @{
            url='https://repo.plify.xyz'
            enabled=$true
            description='Official Production Plify Repository'
            thumbprint=""
        }
    }
}