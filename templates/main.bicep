// Parameters

param appServiceAppName string = 'toylaunch${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location
param storageAccountName string = 'toylaunch${uniqueString(resourceGroup().id)}'

// business logic for toy product launch infrastructure
@allowed([
  'nonprod'
  'prod'
])
param environmentType string

// Variables
var storageAccountSkuName = (environmentType == 'prod') ? 'Standard_GRS' : 'Standard_LRS'

// Resources
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
    name: storageAccountName
    location: location
    sku: {
        name: storageAccountSkuName
    }
    kind: 'StorageV2'
    properties: {
        accessTier: 'Hot'
    }
}

module appService 'modules/appService.bicep' = {
  name: 'appService'
  params: {
    location: location
    appServiceAppName: appServiceAppName
    environmentType: environmentType
  }
}
// Outputs
output appServiceHostname string = appService.outputs.appServiceHostname
