param location string = resourceGroup().location
param environmentName string = 'env-${uniqueString(resourceGroup().id)}'
param apimName string = 'store-api-mgmt-${uniqueString(resourceGroup().id)}'
param minReplicas int = 0
param nodeImage string = 'nginx'
param nodePort int = 3000
param isNodeExternalIngress bool = true
param pythonImage string = 'nginx'
param pythonPort int = 5000
param isPythonExternalIngress bool = false
param goImage string = 'nginx'
param goPort int = 8050
param isGoExternalIngress bool = false
param containerRegistry string
param containerRegistryUsername string

@secure()
param containerRegistryPassword string

var nodeServiceAppName = 'node-app'
var pythonServiceAppName = 'python-app'
var goServiceAppName = 'go-app'

// // container app environment
module environment 'environment.bicep' = {
  name: 'container-app-environment'
  params: {
    environmentName: environmentName
    location: location
  }
}

// create cosmosdb
module cosmosdb 'cosmosdb.bicep' = {
  name: 'cosmosdb'
  params: {
    location: location
    primaryRegion: location
  }
}

// create api management
module apim 'api-management.bicep' = {
  name: 'apim'
  params: {
    apimName: apimName
    publisherName: 'Contoso Store'
    publisherEmail: 'demo@example.com'
    apimLocation: location
  }
}

// Python App
module pythonService 'container-http.bicep' = {
  name: pythonServiceAppName
  params: {
    location: location
    containerAppName: pythonServiceAppName
    environmentId: environment.outputs.environmentId
    containerImage: pythonImage
    containerPort: pythonPort
    isExternalIngress: isPythonExternalIngress
    minReplicas: minReplicas
    containerRegistry: containerRegistry
    containerRegistryUsername: containerRegistryUsername
    containerRegistryPassword: containerRegistryPassword
    secrets: [
      {
        name: 'docker-password'
        value: containerRegistryPassword
      }
    ]
  }
}

resource stateDaprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-01-01-preview' = {
  name: '${environmentName}/orders'
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
      pythonService.name
    ]
  }
}

// Go App
module goService 'container-http.bicep' = {
  name: goServiceAppName
  params: {
    location: location
    containerAppName: goServiceAppName
    environmentId: environment.outputs.environmentId
    containerImage: goImage
    containerPort: goPort
    isExternalIngress: isGoExternalIngress
    minReplicas: minReplicas
    containerRegistry: containerRegistry
    containerRegistryUsername: containerRegistryUsername
    containerRegistryPassword: containerRegistryPassword
  }
}


// node App
module nodeService 'container-http.bicep' = {
  name: nodeServiceAppName
  params: {
    location: location
    containerAppName: nodeServiceAppName
    environmentId: environment.outputs.environmentId
    containerImage: nodeImage
    containerPort: nodePort
    isExternalIngress: isNodeExternalIngress
    minReplicas: minReplicas
    containerRegistry: containerRegistry
    containerRegistryUsername: containerRegistryUsername
    containerRegistryPassword: containerRegistryPassword
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
  }
}

module apimStoreApi 'api-management-api.bicep' = {
  name: 'store-api'
  params: {
    apiName: 'store-api'
    apimInstanceName: apimName
    apiEndPointURL: 'https://${nodeService.outputs.fqdn}/swagger.json'
  }
  dependsOn: [
    apim
    nodeService
  ]
}

output nodeFqdn string = nodeService.outputs.fqdn
output pythonFqdn string = pythonService.outputs.fqdn
output goFqdn string = goService.outputs.fqdn
output apimFqdn string = apim.outputs.fqdn
