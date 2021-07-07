param vaultName string = 'keyVault${uniqueString(resourceGroup().id)}' // must be globally unique
param location string = resourceGroup().location
param sku string = 'Standard'
param tenantId string = ''
param userObjectId string = ''
param vmUserAssignedId string = ''

param accessPolicies array = [
  {
    tenantId: tenantId
    objectId: userObjectId 
    permissions: {
      secrets: [
        'Get'
        'List'
        'Set'
        'Delete'
        'Recover'
        'Backup'
        'Restore'
      ]
    }
  }
  {
    tenantId: tenantId
    objectId: vmUserAssignedId 
    permissions: {
      secrets: [
        'Get'
        'List'
        'Set'
        'Delete'
        'Recover'
        'Backup'
        'Restore'
      ]
    }
  }
]

param enabledForDeployment bool = true
param enabledForTemplateDeployment bool = true
param enabledForDiskEncryption bool = true
param enableRbacAuthorization bool = false
param softDeleteRetentionInDays int = 90

param networkAcls object = {
  ipRules: []
  virtualNetworkRules: []
}

resource keyvault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: vaultName
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: sku
    }
    accessPolicies: accessPolicies
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enableRbacAuthorization: enableRbacAuthorization
    networkAcls: networkAcls
  }
}

output vaultUri string = keyvault.properties.vaultUri
