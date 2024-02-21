metadata description = 'Creates a new storage account'

@description('Specifies the prefix for the storage account.')
@maxLength(24)
param storageAccountName string

@description('Specifies the SKU for the storage account.')
param storageAccountSku string

param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSku
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
}