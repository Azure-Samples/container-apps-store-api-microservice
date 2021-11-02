param apimName string
param apimLocation string = resourceGroup().location
param publisherName string
param publisherEmail string
@description('The pricing tier of this API Management service')
@allowed([
  'Basic'
  'Consumption'
  'Developer'
  'Standard'
  'Premium'
])
param sku string = 'Consumption'

resource storeapim 'Microsoft.ApiManagement/service@2020-12-01' = {
  name: apimName
  location: apimLocation
  sku: {
    name: sku
    capacity: ((sku == 'Consumption') ? 0 : 1)
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
  identity: {
    type: 'SystemAssigned'
  }
}

output apimId string = storeapim.id
output fqdn string = storeapim.properties.gatewayUrl
