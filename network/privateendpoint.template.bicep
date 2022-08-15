@description('Storage Account Privatelink Resource')
param storageAccountPrivateLinkResource string

@description('Storage Account name')
param storageAccountName string

@description('Keyvault Private Link resource.')
param keyvaultPrivateLinkResource string

@description('keyvault name.')
param keyvaultName string

var targetSubResourceDfs = 'dfs'
var targetSubResourceVault = 'vault'

@description('Vnet name for private link')
param vnetName string

@description('Privatelink subnet Id')
param privateLinkSubnetId string

@description('Privatelink subnet Id')
param privateLinkLocation string = resourceGroup().location

var privateDnsNameStorage_var = 'privatelink.dfs.${environment().suffixes.storage}'
var storageAccountPrivateEndpointName_var = '${storageAccountName}privateendpoint'

var privateDnsNameVault_var = 'privatelink.vaultcore.azure.net'
var keyvaultPrivateEndpointName_var = '${keyvaultName}privateendpoint'

resource storageAccountPrivateEndpointName 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: storageAccountPrivateEndpointName_var
  location: privateLinkLocation
  properties: {
    privateLinkServiceConnections: [
      {
        name: storageAccountPrivateEndpointName_var
        properties: {
          privateLinkServiceId: storageAccountPrivateLinkResource
          groupIds: [
            targetSubResourceDfs
          ]
        }
      }
    ]
    subnet: {
      id: privateLinkSubnetId
    }
  }
}
resource privateDnsNameStorage 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsNameStorage_var
  location: 'global'
  tags: {}
  properties: {}
  dependsOn: [
    storageAccountPrivateEndpointName
  ]
}
resource privateDnsNameStorage_vnetName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsNameStorage
  name: vnetName
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    }
    registrationEnabled: false
  }
}
resource storageAccountPrivateEndpointName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: storageAccountPrivateEndpointName
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-dfs-core-windows-net'
        properties: {
          privateDnsZoneId: privateDnsNameStorage.id
        }
      }
    ]
  }
}

resource keyvaultPrivateEndpointName 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: keyvaultPrivateEndpointName_var
  location: privateLinkLocation
  properties: {
    privateLinkServiceConnections: [
      {
        name: keyvaultPrivateEndpointName_var
        properties: {
          privateLinkServiceId: keyvaultPrivateLinkResource
          groupIds: [
            targetSubResourceVault
          ]
        }
      }
    ]
    subnet: {
      id: privateLinkSubnetId
    }
  }
  tags: {}
}
resource privateDnsNameVault 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsNameVault_var
  location: 'global'
  tags: {}
  properties: {}
  dependsOn: [
    keyvaultPrivateEndpointName
  ]
}
resource privateDnsNameVault_vnetName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsNameVault
  name: vnetName
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    }
    registrationEnabled: false
  }
}
resource keyvaultPrivateEndpointName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: keyvaultPrivateEndpointName
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-vaultcore-azure-net'
        properties: {
          privateDnsZoneId: privateDnsNameVault.id
        }
      }
    ]
  }
}


