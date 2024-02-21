param recoveryServicesVaultName string
param location string = resourceGroup().location

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2021-01-01' = {
  name: recoveryServicesVaultName
  location: location
  properties: {}
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
}