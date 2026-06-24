// Virtual Network Module
// Creates VNet with subnets for AKS, App Gateway, and app services
// Implements network security best practices (NSGs, routing)

param location string
param resourceSuffix string
param tags object
param addressSpaces array

var vnetName = 'vnet-${resourceSuffix}'
var aksSubnetName = 'subnet-aks-${resourceSuffix}'
var appSubnetName = 'subnet-app-${resourceSuffix}'
var gatewaySubnetName = 'GatewaySubnet'

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressSpaces
    }
    subnets: [
      {
        name: aksSubnetName
        properties: {
          addressPrefix: addressSpaces[0] == '10.0.0.0/16' ? '10.0.1.0/24' : '10.1.1.0/24'
          networkSecurityGroup: {
            id: aksNsg.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: appSubnetName
        properties: {
          addressPrefix: addressSpaces[0] == '10.0.0.0/16' ? '10.0.2.0/24' : '10.1.2.0/24'
          networkSecurityGroup: {
            id: appNsg.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: gatewaySubnetName
        properties: {
          addressPrefix: addressSpaces[0] == '10.0.0.0/16' ? '10.0.3.0/24' : '10.1.3.0/24'
          delegations: []
        }
      }
    ]
  }
}

// Network Security Group for AKS
resource aksNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-aks-${resourceSuffix}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'allow-internal-vnet'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-https'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-http'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Network Security Group for App Services
resource appNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-app-${resourceSuffix}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'allow-from-aks'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: addressSpaces[0] == '10.0.0.0/16' ? '10.0.1.0/24' : '10.1.1.0/24'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'deny-all-inbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output aksSubnetId string = '${vnet.id}/subnets/${aksSubnetName}'
output appSubnetId string = '${vnet.id}/subnets/${appSubnetName}'
output gatewaySubnetId string = '${vnet.id}/subnets/${gatewaySubnetName}'
