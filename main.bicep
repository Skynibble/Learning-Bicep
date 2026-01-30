resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
    name: 'toysa${uniqueString(resourceGroup().id)}'
    location: 'Central US'
    sku: {
        name: 'Standard_LRS'
    }
    kind: 'StorageV2'
    properties: {
        accessTier: 'Hot'
    }
}


