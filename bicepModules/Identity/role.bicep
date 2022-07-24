param principalId string
param roleGuid string
param name string

resource role_assignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: name
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleGuid)
  }
}
