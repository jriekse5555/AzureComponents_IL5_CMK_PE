metadata name = 'Regulated Industry Azure Key Vault (AKV) Deployment'
metadata description = 'Create an Azure Key Vault (AKV) that is a private vault deployed into a virtual network and is integrated to a Log Analytics workspace for diagnostics.'

@description('Optional. Location for the resources to be deployed to.')
param location string = resourceGroup().location

@description('Optional. Virtual Network Name.')
param vnetName string

@description('Optional. Virtual Network Resource Group.')
param vnetRgp string

@description('Required. Keyvault log analytics resource id.')
param logAnalyticsResourceId string

@description('Required. Private Link Subnet Name.')
param privateLinkSubnetName string

@description('Optional. Keyvault Name.')
param kvtName string

@description('Optional. Keyvault Resource Group.')
param kvtRgpName string

@description('Optional. Public endpoint firewall.')
param networkAcls object = {
  bypass: 'AzureServices'
  defaultAction: 'Deny'
  ipRules: []
  virtualNetworkRules: []
}

@description('Optional. Purge protection required to store cmks.')
param enablePurgeProtection bool = true

@description('Required. Keyvault private dns zone resource id.')
param kvtPrivateDNSZoneResourceId string

@description('Required. Azure AD group object ID to grant full access to keyvault')
param kvtAadObjId string

@description('Provides full control to Azure AD group')
var accessPolicies = [
  {
    tenantId: subscription().tenantId
    objectId: kvtAadObjId
    permissions: {
      certificates: [
        'All'
      ]
      keys: [
        'All'
      ]
      secrets: [
        'All'
      ]
    }
  }
]

@description('Calculate private link subnet resource id')
resource privateLinkSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  name: '${vnetName}/${privateLinkSubnetName}'
  scope: resourceGroup(vnetRgp)
}

@description('Creates keyvault')
module keyvault '../../carmlBicepModules/Microsoft.KeyVault/vaults/deploy.bicep' = {
  name: 'keyvault-${uniqueString(deployment().name)}'
  scope: resourceGroup(kvtRgpName)
  params: {
    name: kvtName
    location: location
    enableVaultForDeployment: true
    enableVaultForDiskEncryption: true
    enableVaultForTemplateDeployment: true
    enablePurgeProtection: enablePurgeProtection
    networkAcls: networkAcls
    diagnosticWorkspaceId: logAnalyticsResourceId
    accessPolicies: accessPolicies
    privateEndpoints: [
      {
        name: '${kvtName}-Endpoint-01'
        subnetResourceId: privateLinkSubnet.id
        privateDnsZoneGroups: [
          {
            privateDNSResourceIds: [
              kvtPrivateDNSZoneResourceId
            ]
          }
        ]
        service: 'vault'
      }
    ]
  }
}
