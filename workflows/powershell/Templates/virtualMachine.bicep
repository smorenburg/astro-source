param virtualNetworkResourceGroupName string
param virtualNetworkName string
param subnetName string
param virtualMachineName string
param virtualMachineSize string
param image object
param osDiskSizeGB int
param osDiskType string = 'Premium_LRS'

param adminUsername string

@secure()
param adminPassword string

param location string = resourceGroup().location

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  scope: resourceGroup(virtualNetworkResourceGroupName)
  name: virtualNetworkName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' existing = {
  parent: virtualNetwork
  name: subnetName
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'nic-${virtualMachineName}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'subnet-config'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: virtualMachineName
  location: location
  identity: {
     type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    osProfile: {
     computerName: toUpper(virtualMachineName)
     adminUsername: adminUsername
     adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: image
      osDisk: {
        name: 'osdisk-${virtualMachineName}'
        osType: 'Linux'
        diskSizeGB: osDiskSizeGB
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: osDiskType
        }        
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
}
