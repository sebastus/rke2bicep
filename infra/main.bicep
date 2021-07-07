targetScope = 'resourceGroup'

param resGroupName string = 'bigbang'
param location string = 'uksouth'
param suffix string = 'bigbang-${substring(uniqueString(resGroupName), 0, 4)}'
param tenantId string = ''
param userObjectId string = ''

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

var serverCustomData1 = replace(serverCustomData.outputs.customDataString, '{vaultBaseUrl}', kv.outputs.vaultUri)
var serverCustomData2 = replace(serverCustomData1, '{audience}', 'https://${substring(environment().suffixes.keyvaultDns, 1)}')
module vmServer1 'modules/vm.bicep' = {
  name: 'rke2-server'
  scope: resourceGroup()
  params: {
    vmName: 'rke2-server'
    adminUsername: 'greg'
    authenticationType: 'sshPublicKey'
    adminPasswordOrKey: sshPublicKey
    location: location
    vmSize: 'Standard_D4_v4'
    netVnet: network.outputs.vnetName
    netSubnet: network.outputs.aksSubnetName
    customData: serverCustomData2
    userAssignedIdentity: vmIdentity.id
  }
}

var agentCustomData1 = replace(agentCustomData.outputs.customDataString, '<rke2server>', vmServer1.outputs.hostname)
var agentCustomData2 = replace(agentCustomData1, '{audience}', 'https://${substring(environment().suffixes.keyvaultDns, 1)}')
var agentCustomData3 = replace(agentCustomData2, '{vaultBaseUrl}', kv.outputs.vaultUri)
module vmAgent1 'modules/vm.bicep' = {
  name: 'rke2-agent01'
  scope: resourceGroup()
  params: {
    vmName: 'rke2-agent01'
    adminUsername: 'greg'
    authenticationType: 'sshPublicKey'
    adminPasswordOrKey: sshPublicKey
    location: location
    vmSize: 'Standard_D4_v4'
    netVnet: network.outputs.vnetName
    netSubnet: network.outputs.aksSubnetName
    customData: agentCustomData3
    userAssignedIdentity: vmIdentity.id
  }
}

