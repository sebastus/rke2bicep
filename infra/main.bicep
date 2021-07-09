targetScope = 'resourceGroup'

param resGroupName string = 'bigbang'
param location string = 'uksouth'
param suffix string = 'bigbang-${substring(uniqueString(resGroupName), 0, 4)}'
param tenantId string = ''
param userObjectId string = ''
param userIPAddress string
param userName string = 'somebody'

var sshPublicKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDWuqe/MKBbgm9dWEHq9Qr9/qliQSbv6OQ/43SjQoKGBKn8QKKEAaSm8l9PAgKQ7tW/frSAX8VrD+pSFh3MqphFWZTfOvUZQHmts7TdoyxVTgfGO5ThQwHuQpBXEQlHzcM+Q0WpTWvGpc8+3IeXdMZAwcPzaIx1eotFFIZd5+n79cf3jVGA0xb0yAdRl+vN89xuPSbD1Mj5wHvZmci0lEA2MXdngIGbJsFy0BAJMAZzYx9gV1OZQ5M4gEJl/pjQNNpjWQ3mvCyWizvUBq19Ni0OQDFMJfLajN8bnVdxvk1AY4ST6j6EGjjYUuDpmZRab9hR+PO4cOAKfZtueEnXb7gemP2pqtrvnYUXHJ9CsVQ3EKJNGJFAaq5yPH2Ie0/PnkaLdafk20TZBsqHJ4TpziHv8Iw4z84ZX6YTajLyRTZGLWQsLOIfYUTfK7z4fy6wqBLYn5f27AgDy2dBG5VhmTv+XUVrMnvEi68u13Q6YbNQAS1bDXNqWIM9jdCpY8MTGlU= root@golive-surface-laptop'
var keyVaultSecretsOfficer = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')

module network 'modules/network.bicep' = {
  scope: resourceGroup()
  name: 'network'
  params: {
    location: location
    suffix: suffix
  }
}

module serverCustomData 'modules/serverCustomData.bicep' = {
  name: 'serverCustomData'
}

module agentCustomData 'modules/agentCustomData.bicep' = {
  name: 'agentCustomData'
}

module nsgRules 'modules/nsg-rules.bicep' = {
  name: 'nsgRules'
}

resource vmIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'golive-rke2'
  location: location
}

resource vmKVSecretsOfficer 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, keyVaultSecretsOfficer)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: keyVaultSecretsOfficer
    principalId: vmIdentity.properties.principalId
  }
}

module kv 'modules/kv.bicep' = {
  name: 'kv'
  scope: resourceGroup()
  params: {
    tenantId: tenantId
    userObjectId: userObjectId
    vmUserAssignedId: vmIdentity.properties.principalId
  }
}

var Port22_Rule = { 
  name: 'SSH'
  properties: {
    priority: 1000
    protocol: 'Tcp'
    access: 'Allow'
    direction: 'Inbound'
    sourceAddressPrefix: userIPAddress
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '22'
  }
}

var serverNsgRules = [ 
  Port22_Rule
  nsgRules.outputs.port10250
  nsgRules.outputs.port6443
  nsgRules.outputs.port9345
  nsgRules.outputs.nodePort 
]

param serverName string = 'rke2-server'

module serverNsg 'modules/nsg.bicep' = {
  name: 'serverNsg'
  params: {
    networkSecurityGroupName: '${serverName}Nsg'
    location: location
    rules: serverNsgRules
  }
}

var serverCustomData1 = replace(serverCustomData.outputs.customDataString, '{vaultBaseUrl}', kv.outputs.vaultUri)
var serverCustomData2 = replace(serverCustomData1, '{audience}', 'https://${substring(environment().suffixes.keyvaultDns, 1)}')
var serverCustomData3 = replace(serverCustomData2, '{tenant_id}', tenantId)
var serverCustomData4 = replace(serverCustomData3, '{resource_group}', resourceGroup().name)
var serverCustomData5 = replace(serverCustomData4, '{location}', location)
var serverCustomData6 = replace(serverCustomData5, '{subnet_name}', network.outputs.aksSubnetName)
var serverCustomData7 = replace(serverCustomData6, '{nsg_name}', serverNsg.outputs.name)
var serverCustomData8 = replace(serverCustomData7, '{vnet_name}', network.outputs.vnetName)
var serverCustomData9 = replace(serverCustomData8, '{route_table_name}', '${serverName}RouteTable')
var serverCustomDataA = replace(serverCustomData9, '{username}', userName)
var serverCustomDataB = replace(serverCustomDataA, '{clientID}', vmIdentity.properties.clientId)

module vmServer1 'modules/vm.bicep' = {
  name: serverName
  scope: resourceGroup()
  params: {
    vmName: serverName
    adminUsername: userName
    authenticationType: 'sshPublicKey'
    adminPasswordOrKey: sshPublicKey
    location: location
    vmSize: 'Standard_D4_v4'
    netVnet: network.outputs.vnetName
    netSubnet: network.outputs.aksSubnetName
    networkSecurityGroupID: serverNsg.outputs.id
    customData: serverCustomDataB
    userAssignedIdentity: vmIdentity.id
  }
}

param agentName string = 'rke2-agent01'

module agentNsg 'modules/nsg.bicep' = {
  name: 'agentNsg'
  params: {
    networkSecurityGroupName: '${agentName}Nsg'
    location: location
    rules: [
      Port22_Rule
    ]
  }
}

var agentCustomData1 = replace(agentCustomData.outputs.customDataString, '<rke2server>', vmServer1.outputs.privateIP)
var agentCustomData2 = replace(agentCustomData1, '{audience}', 'https://${substring(environment().suffixes.keyvaultDns, 1)}')
var agentCustomData3 = replace(agentCustomData2, '{vaultBaseUrl}', kv.outputs.vaultUri)
module vmAgent1 'modules/vm.bicep' = {
  name: agentName
  scope: resourceGroup()
  dependsOn: [
    vmServer1
  ]
  params: {
    vmName: agentName
    adminUsername: userName
    authenticationType: 'sshPublicKey'
    adminPasswordOrKey: sshPublicKey
    location: location
    vmSize: 'Standard_D4_v4'
    netVnet: network.outputs.vnetName
    netSubnet: network.outputs.aksSubnetName
    networkSecurityGroupID: agentNsg.outputs.id
    customData: agentCustomData3
    userAssignedIdentity: vmIdentity.id
  }
}

