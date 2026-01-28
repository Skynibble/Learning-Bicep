@description('The host name (address) of the origin server. Example: myapp.azurewebsites.net')
param originHostName string

@description('Front Door profile name.')
param profileName string = 'afd-${uniqueString(resourceGroup().id)}'

@description('Front Door endpoint name (must be globally unique).')
param endpointName string = 'endpoint-${uniqueString(resourceGroup().id)}'

@description('If true, only allow HTTPS from clients.')
param httpsOnly bool = true

var originGroupName = 'originGroup1'
var originName = 'origin1'
var routeName = 'route1'

resource afdProfile 'Microsoft.Cdn/profiles@2024-09-01' = {
  name: profileName
  location: 'global'
  sku: {
    name: 'Standard_AzureFrontDoor' // or 'Premium_AzureFrontDoor'
  }
}

resource afdEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2024-09-01' = {
  parent: afdProfile
  name: endpointName
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource originGroup 'Microsoft.Cdn/profiles/originGroups@2024-09-01' = {
  parent: afdProfile
  name: originGroupName
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
  }
}

resource origin 'Microsoft.Cdn/profiles/originGroups/origins@2024-09-01' = {
  parent: originGroup
  name: originName
  properties: {
    hostName: originHostName
    originHostHeader: originHostName
    httpPort: 80
    httpsPort: 443
    priority: 1
    weight: 1000
  }
}

resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2024-09-01' = {
  parent: afdEndpoint
  name: routeName
  dependsOn: [
    origin // ensure origin group isn't empty when route is created
  ]
  properties: {
    originGroup: {
      id: originGroup.id
    }
    supportedProtocols: httpsOnly ? [
      'Https'
    ] : [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: httpsOnly ? 'HttpsOnly' : 'MatchRequest'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: httpsOnly ? 'Enabled' : 'Disabled'

    // This is where your old endpoint caching/compression settings go in AFD:
    cacheConfiguration: {
      queryStringCachingBehavior: 'IgnoreQueryString'
      compressionSettings: {
        isCompressionEnabled: true
        contentTypesToCompress: [
          'text/plain'
          'text/html'
          'text/css'
          'application/x-javascript'
          'text/javascript'
        ]
      }
    }
  }
}

@description('The host name of the Front Door endpoint.')
output endpointHostName string = afdEndpoint.properties.hostName
