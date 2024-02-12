param virtualNetworkName string
param virtualNetworkAddressPrefix string
param subnetName string
param subnetAddressPrefix string

param location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
        addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
    ]
  }
}