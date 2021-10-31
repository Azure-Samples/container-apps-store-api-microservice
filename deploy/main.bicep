param location string = 'northcentralusstage'
param environmentName string = 'env-${uniqueString(resourceGroup().id)}'
param apimName string = 'store-api-mgmt-${uniqueString(resourceGroup().id)}'
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
  }
}

// create cosmosdb
module cosmosdb 'cosmosdb.bicep' = {
  name: 'cosmosdb'
  params: {
    
  }
}

// create api management
module apim 'api-management.bicep' = {
  name: 'apim'
  params: {
    apimName: apimName
    apimLocation: 'northcentralus'
    publisherName: 'Contoso Store'
    publisherEmail: 'demo@example.com'
  }
}

// Python App
module pythonService 'container-http.bicep' = {
  name: pythonServiceAppName
  params: {
    containerAppName: pythonServiceAppName
    location: 'northcentralusstage'
    environmentId: environment.outputs.environmentId
    containerImage: pythonImage
    containerPort: pythonPort
    isExternalIngress: isPythonExternalIngress
    containerRegistry: containerRegistry
    containerRegistryUsername: containerRegistryUsername
    containerRegistryPassword: containerRegistryPassword
    daprComponents: [
      {
        name: 'orders'
        type: 'state.azure.cosmosdb'
        version: 'v1'
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
      }
    ]
    secrets: [
      {
        name: 'docker-password'
        value: containerRegistryPassword
      }
      {
        name: 'masterkey'
        value: cosmosdb.outputs.primaryMasterKey
      }
    ]
  }
}


// Go App
module goService 'container-http.bicep' = {
  name: goServiceAppName
  params: {
    containerAppName: goServiceAppName
    location: 'northcentralusstage'
    environmentId: environment.outputs.environmentId
    containerImage: goImage
    containerPort: goPort
    isExternalIngress: isGoExternalIngress
    containerRegistry: containerRegistry
    containerRegistryUsername: containerRegistryUsername
    containerRegistryPassword: containerRegistryPassword
  }
}


// node App
module nodeService 'container-http.bicep' = {
  name: nodeServiceAppName
  params: {
    containerAppName: nodeServiceAppName
    location: 'northcentralusstage'
    environmentId: environment.outputs.environmentId
    containerImage: nodeImage
    containerPort: nodePort
    isExternalIngress: isNodeExternalIngress
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
