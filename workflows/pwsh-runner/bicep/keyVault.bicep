param keyVaultName string
param objectId string
param location string = resourceGroup().location

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: false
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableRbacAuthorization: false
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: objectId
        permissions: {
          keys: [
            'get'
          ]
          secrets: [
            'list'
            'get'
            'set'
          ]
        }
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: tenant().tenantId
  }
}