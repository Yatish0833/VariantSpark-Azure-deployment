@minLength(3)
@maxLength(24)
@description('Name of the storage account')
param storageAccountName string

param storageContainerName string = 'data'

param databricksPublicSubnetId string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
@description('Storage Account Sku')
param storageAccountSku string = 'Standard_LRS'

// @allowed([
//   'Standard'
//   'Premium'
// ])
// @description('Storage Account Sku tier')
// param storageAccountSkuTier string = 'Premium'

param storageLocation string

@description('Enable or disable Blob encryption at Rest.')
param encryptionEnabled bool = true

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  tags: {
    displayName: storageAccountName
    type: 'Storage'
  }
  location: storageLocation
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: databricksPublicSubnetId
          action: 'Allow'
          state: 'succeeded'
        }
      ]
      ipRules: []
      defaultAction: 'Deny'
    }
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: encryptionEnabled
        }
        file: {
          enabled: encryptionEnabled
        }
      }
    }
  }
  sku: {
    name: storageAccountSku
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  name: '${storageAccountName_resource.name}/default/${storageContainerName}'
}

//var keysObj = listKeys(resourceId('Microsoft.Storage/storageAccounts', storageAccountName), '2022-05-01')
#disable-next-line outputs-should-not-contain-secrets // Does not contain a password
//output key1 string = keysObj.keys[0].value
#disable-next-line outputs-should-not-contain-secrets // Does not contain a password
//output key2 string = keysObj.keys[1].value
output storageaccount_id string = storageAccountName_resource.id
// output container_obj object = container.properties
