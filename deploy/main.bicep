param location string = resourceGroup().location
param environmentName string = 'env-${uniqueString(resourceGroup().id)}'

param minReplicas int = 0

param nodeImage string 
param nodePort int = 3000
var nodeServiceAppName = 'node-app'

param pythonImage string
param pythonPort int = 5000
var pythonServiceAppName = 'python-app'

param goImage string
param goPort int = 8050
var goServiceAppName = 'go-app'

param apimName string = 'store-api-mgmt-${uniqueString(resourceGroup().id)}'
param deployApim bool = true
param isPrivateRegistry bool = true

param containerRegistry string
param containerRegistryUsername string = 'testUser'
@secure()
param containerRegistryPassword string = ''
param registryPassword string = 'registry-password'


// Container Apps Environment 
module environment 'environment.bicep' = {
  name: '${deployment().name}--environment'
  params: {
    environmentName: environmentName
    location: location
    appInsightsName: '${environmentName}-ai'
    logAnalyticsWorkspaceName: '${environmentName}-la'
  }
}

// Cosmosdb
module cosmosdb 'cosmosdb.bicep' = {
  name: '${deployment().name}--cosmosdb'
  params: {
    location: location
    primaryRegion: location
  }
}

// API Management
module apim 'api-management.bicep' = if (deployApim) {
  name: '${deployment().name}--apim'
  params: {
    apimName: apimName
    publisherName: 'Contoso Store'
    publisherEmail: 'demo@example.com'
    apimLocation: location
  }
}


// Python App
module pythonService 'container-http.bicep' = {
  name: '${deployment().name}--${pythonServiceAppName}'
  dependsOn: [
    environment
  ]
  params: {
    enableIngress: true
    isExternalIngress: false
    location: location
    environmentName: environmentName
    containerAppName: pythonServiceAppName
    containerImage: pythonImage
    containerPort: pythonPort
    isPrivateRegistry: isPrivateRegistry 
    minReplicas: minReplicas
    containerRegistry: containerRegistry
    registryPassword: registryPassword
    containerRegistryUsername: containerRegistryUsername
    revisionMode: 'Single'
    secrets: [
      {
        name: registryPassword
        value: containerRegistryPassword
      }
    ]
  }
}

resource stateDaprComponent 'Microsoft.App/managedEnvironments/daprComponents@2023-08-01-preview' = {
  name: '${environmentName}/orders'
  dependsOn: [
    environment
  ]
  properties: {
    componentType: 'state.azure.cosmosdb'
    version: 'v1'
    secrets: [
      {
        name: 'masterkey'
        value: cosmosdb.outputs.primaryMasterKey
      }
    ]
    metadata: [
      {
        name: 'url'
        value: cosmosdb.outputs.documentEndpoint
      }
      {
        name: 'database'
        value: 'ordersDb'
      }
      {
        name: 'collection'
        value: 'orders'
      }
      {
        name: 'masterkey'
        secretRef: 'masterkey'
      }
    ]
    scopes: [
      pythonServiceAppName
    ]
  }
}

// Go App
module goService 'container-http.bicep' = {
  name: '${deployment().name}--${goServiceAppName}'
  dependsOn: [
    environment
  ]
  params: {
    enableIngress: true
    isExternalIngress: false
    location: location
    environmentName: environmentName
    containerAppName: goServiceAppName
    containerImage: goImage
    containerPort: goPort
    isPrivateRegistry: isPrivateRegistry
    minReplicas: minReplicas
    containerRegistry: containerRegistry
    registryPassword: registryPassword
    containerRegistryUsername: containerRegistryUsername
    revisionMode: 'Single'
    secrets: isPrivateRegistry ? [
      {
        name: registryPassword
        value: containerRegistryPassword
      }
    ] : []
  }
}


// Node App
module nodeService 'container-http.bicep' = {
  name: '${deployment().name}--${nodeServiceAppName}'
  dependsOn: [
    environment
  ]
  params: {
    enableIngress: true 
    isExternalIngress: true
    location: location
    environmentName: environmentName
    containerAppName: nodeServiceAppName
    containerImage: nodeImage
    containerPort: nodePort
    minReplicas: minReplicas
    isPrivateRegistry: isPrivateRegistry 
    containerRegistry: containerRegistry
    registryPassword: registryPassword
    containerRegistryUsername: containerRegistryUsername
    revisionMode: 'Multiple'
    env: [
      {
        name: 'ORDER_SERVICE_NAME'
        value: pythonServiceAppName
      }
      {
        name: 'INVENTORY_SERVICE_NAME'
        value: goServiceAppName
      }
    ]
    secrets: [
      {
        name: registryPassword
        value: containerRegistryPassword
      }
    ]
  }
}

module apimStoreApi 'api-management-api.bicep' = if (deployApim) {
  name: '${deployment().name}--apim-store-api'
  dependsOn: [
    apim
    nodeService
  ]
  params: {
    apiName: 'store-api'
    apimInstanceName: apimName
    apiEndPointURL: 'https://${nodeService.outputs.fqdn}/swagger.json'
  }
}

output nodeFqdn string = nodeService.outputs.fqdn
output pythonFqdn string = pythonService.outputs.fqdn
output goFqdn string = goService.outputs.fqdn
output apimFqdn string = deployApim ? apim.outputs.fqdn : 'API Management not deployed'
