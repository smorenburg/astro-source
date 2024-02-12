param virtualNetworkResourceGroupName string
param virtualNetworkName string
param subnetName string
param virtualMachineName string
param availabilityZone string
param virtualMachineSize string
param hostname string
param image object
param osDiskSizeGb int
param osDiskType string

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
  zones: [
    availabilityZone
  ]
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    osProfile: {
     computerName: hostname
     adminUsername: adminUsername
     adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        name: 'osdisk-${virtualMachineName}'
        osType: 'Linux'
        diskSizeGB: osDiskSizeGb
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
