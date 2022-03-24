param containerAppName string
param location string = resourceGroup().location
param environmentId string
param containerImage string
param containerPort int
param isExternalIngress bool
param containerRegistry string
param containerRegistryUsername string
param env array = []
param minReplicas int = 0
param secrets array = [
  {
    name: 'docker-password'
    value: containerRegistryPassword
  }
]

@allowed([
  'multiple'
  'single'
])
param revisionMode string = 'multiple'

@secure()
param containerRegistryPassword string

var cpu = json('0.5')
var memory = '500Mi'
var registrySecretRefName = 'docker-password'

resource containerApp 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      // activeRevisionsMode: revisionMode
      secrets: secrets
      registries: [
        {
          server: containerRegistry
          username: containerRegistryUsername
          passwordSecretRef: registrySecretRefName
        }
      ]
      ingress: {
        external: isExternalIngress
        targetPort: containerPort
        transport: 'auto'
        // traffic: [
        //   {
        //     weight: 100
        //     latestRevision: true
        //   }
        // ]
      }
      dapr: {
        enabled: true
        appPort: containerPort
        appId: containerAppName
      }
    }
    template: {
      // revisionSuffix: 'somevalue'
      containers: [
        {
          image: containerImage
          name: containerAppName
          env: env
          // resources: {
          //   cpu: cpu
          //   memory: memory
          // }
        }
      ]
      scale: {
        minReplicas: minReplicas
      //  maxReplicas: 10
      //   rules: [{
      //     name: 'httpscale'
      //     http: {
      //       metadata: {
      //         concurrentRequests: 100
      //       }
      //     }
      //   }
      //   ]
      }
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
