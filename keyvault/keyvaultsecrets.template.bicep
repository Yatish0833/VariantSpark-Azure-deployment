param keyVaultName string
param LogAWkspId string

@secure()
param LogAWkspkey string
param StorageAccountName string



resource keyVaultAddSecretsLogAWkspId 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: '${keyVaultName}/LogAWkspId'
  properties: {
    contentType: 'text/plain'
    value: LogAWkspId
  }
}
resource keyVaultAddSecretsLogAWkspkey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: '${keyVaultName}/LogAWkspkey'
  properties: {
    contentType: 'text/plain'
    value: LogAWkspkey
  }
}
resource keyVaultAddSecretsStg1 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: '${keyVaultName}/StorageAccountKey1'
  properties: {
    contentType: 'text/plain'
    value: listKeys(StorageAccountName.value, '2021-09-01').keys[0].value
  }
}
resource keyVaultAddSecretsStg2 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: '${keyVaultName}/StorageAccountKey2'
  properties: {
    contentType: 'text/plain'
    value: StorageAccountKey2
  }
}


