targetScope='subscription'

param resourceLocation string
param resourceGroupName string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: resourceLocation
}