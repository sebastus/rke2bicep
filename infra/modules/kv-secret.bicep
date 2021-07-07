// create secret
resource secret 'Microsoft.KeyVault/vaults/secrets@2018-02-14' = {
  name: '${keyvault.name}/${secretName}'
  properties: {
    value: secretValue
  }
}

