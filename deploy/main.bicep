param location string = resourceGroup().location
param environmentName string = 'env-${uniqueString(resourceGroup().id)}'
param nodeImage string 
param pythonImage string
param goImage string
param apimName string = 'store-api-mgmt-${uniqueString(resourceGroup().id)}'
param deployApim bool = true

// Container Apps Environment w/ CosmosDB and Component
module myenv 'br/public:app/dapr-containerapps-environment:1.0.1' = {
  name: environmentName
  params: {
    location: location
    nameseed: 'store'
    applicationEntityName: 'orders'
    daprComponentName: 'orders'
    daprComponentType: 'state.azure.cosmosdb'
    daprComponentScopes: [
      'python-app'
    ]
  }
}

// Python App
module pythonService 'br/public:app/dapr-containerapp:1.0.1' = {
  name: 'store-python-app'
  params: {
    location: location
    containerAppEnvName: myenv.outputs.containerAppEnvironmentName
    externalIngress: false
    containerAppName: 'python-app'
    containerImage: pythonImage
    targetPort: 5000
  }
}

// Go App
module goService 'br/public:app/dapr-containerapp:1.0.1' = {
  name: 'store-go-app'
  params: {
    location: location
    containerAppEnvName: myenv.outputs.containerAppEnvironmentName
    externalIngress: false
    containerAppName: 'go-app'
    containerImage: goImage
    targetPort: 8050 
  }
}

// Node App
module nodeService 'br/public:app/dapr-containerapp:1.0.1' = {
  name: 'store-node-app'
  params: {
    location: location
    containerAppEnvName: myenv.outputs.containerAppEnvironmentName
    containerAppName: 'node-app'
    revisionMode: 'Multiple'
    containerImage: nodeImage
    targetPort: 300
    environmentVariables: [
      {
        name: 'ORDER_SERVICE_NAME'
        value: 'python-app'
      }
      {
        name: 'INVENTORY_SERVICE_NAME'
        value: 'go-app'
      }
    ]
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

module apimStoreApi 'api-management-api.bicep' = if (deployApim) {
  name: '${deployment().name}--apim-store-api'
  dependsOn: [
    apim
    nodeService
  ]
  params: {
    apiName: 'store-api'
    apimInstanceName: apimName
    apiEndPointURL: 'https://${nodeService.outputs.containerAppFQDN}/swagger.json'
  }
}

output nodeFqdn string = nodeService.outputs.containerAppFQDN
output pythonFqdn string = pythonService.outputs.containerAppFQDN
output goFqdn string = goService.outputs.containerAppFQDN
output apimFqdn string = deployApim ? apim.outputs.fqdn : 'API Management not deployed'
