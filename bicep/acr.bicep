// Container Registry module
module acr 'Microsoft.ContainerRegistry/registries@2020-06-01' = {
  name: 'myAcr'
  location: resourceGroup().location
  sku: {
    name: 'Basic'
  }
}
