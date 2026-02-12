@description('Name of the Azure Container Registry')
param registryName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('SKU of the ACR (Basic, Standard, Premium)')
param sku string = 'Premium'

@description('Enable admin user (not recommended for production)')
param adminUserEnabled bool = false

@description('Name of the Virtual Network')
param vnetName string

@description('Name of the subnet for the private endpoint')
param subnetName string

@description('Name of the user-assigned managed identity')
param identityName string = 'mi-test1'

@description('Name of the private endpoint')
param privateEndpointName string = 'pe-test1'

/* ---------------------------
   Container Registry
---------------------------- */
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: registryName
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: 'Disabled' // REQUIRED for private endpoint only
  }
}

/* ---------------------------
   User Assigned Managed Identity
---------------------------- */
resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

/* ---------------------------
   Private DNS Zone
---------------------------- */
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
}

/* ---------------------------
   Existing VNet + Subnet
---------------------------- */
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  parent: vnet
  name: subnetName
}

/* ---------------------------
   Private Endpoint
---------------------------- */
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'acrConnection'
        properties: {
          privateLinkServiceId: acr.id
          groupIds: [
            'registry' // REQUIRED for ACR
          ]
        }
      }
    ]
  }
}

/* ---------------------------
   Private DNS Zone Group
---------------------------- */
resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  name: 'acr-dns-zone-group'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'acrDnsZoneConfig'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

/* ---------------------------
   Outputs
---------------------------- */
output acrLoginServer string = acr.properties.loginServer
output managedIdentityId string = userIdentity.id
output privateEndpointId string = privateEndpoint.id
