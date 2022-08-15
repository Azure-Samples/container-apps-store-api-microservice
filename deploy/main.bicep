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

// Container Apps Environment w/ CosmosDB and Component
module myenv 'br/public:app/dapr-containerapps-environment:1.0.1' = {
  name: environmentName
  params: {
    location: location
    nameseed: 'state-cos'
    applicationEntityName: 'orders'
    daprComponentName: 'orders'
    daprComponentType: 'state.azure.cosmosdb'
    daprComponentScopes: [
      pythonServiceAppName
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
    containerAppName: pythonServiceAppName
    containerImage: pythonImage
    minReplicas: minReplicas 
    targetPort: pythonPort
  }
}

// Go App
module goService 'br/public:app/dapr-containerapp:1.0.1' = {
  name: 'store-go-app'
  params: {
    location: location
    containerAppEnvName: myenv.outputs.containerAppEnvironmentName
    externalIngress: false
    containerAppName: goServiceAppName
    containerImage: goImage
    minReplicas: minReplicas
    targetPort: goPort 
  }
}

// Node App
module nodeService 'br/public:app/dapr-containerapp:1.0.1' = {
  name: 'store-node-app'
  params: {
    location: location
    containerAppEnvName: myenv.outputs.containerAppEnvironmentName
    containerAppName: nodeServiceAppName
    containerImage: nodeImage
    targetPort: nodePort
    minReplicas: minReplicas
    environmentVariables: [
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
