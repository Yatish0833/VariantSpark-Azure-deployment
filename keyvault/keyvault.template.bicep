@description('Specifies the name of the key vault.')
param keyVaultName string

@description('Specifies the Azure location where the key vault should be created.')
param keyVaultLocation string

@allowed([
  true
  false
])
@description('Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.')
param enabledForDeployment bool = false

@allowed([
  true
  false
])
@description('Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
param enabledForTemplateDeployment bool = false

@description('Specifies whether protection against purge is enabled for this vault.')
param enablePurgeProtection bool = true

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

@description('Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.')
param objectId string

@allowed([
  'standard'
  'premium'
])
@description('Specifies whether the key vault is a standard vault or a premium vault.')
param keyVaultSkuTier string = 'standard'
param tagValues object = {}

param enablesSoftDelete bool

resource keyVaultName_resource 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: keyVaultLocation
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enablePurgeProtection: enablePurgeProtection
    enableSoftDelete: enablesSoftDelete
    tenantId: tenantId
    accessPolicies: [
      {
        objectId: objectId
        tenantId: tenantId
        permissions: {
          secrets: [
            'list'
            'get'
            'set'
          ]
        }
      }
    ]
    sku: {
      name: keyVaultSkuTier
      family: 'A'
    }
    softDeleteRetentionInDays: 7
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    }
  }
  tags: tagValues
}

output keyvault_id string = keyVaultName_resource.id
output keyvault_uri string = keyVaultName_resource.properties.vaultUri
