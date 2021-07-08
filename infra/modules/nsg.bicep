param networkSecurityGroupName string
param location string
param rules array = [
  {}
]

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [for rule in rules: {
      name: rule.name
      properties: {
        priority: rule.properties.priority
        protocol: rule.properties.protocol
        access: rule.properties.access 
        direction: rule.properties.direction
        sourceAddressPrefix: rule.properties.sourceAddressPrefix
        sourcePortRange: rule.properties.sourcePortRange
        destinationAddressPrefix: rule.properties.destinationAddressPrefix
        destinationPortRange: rule.properties.destinationPortRange
      }
    }]
  }
}

output id string = nsg.id
output name string = nsg.name
