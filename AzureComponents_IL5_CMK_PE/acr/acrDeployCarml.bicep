@description('Required. Virtual Network Name.')
param vnetName string

@description('Required. Virtual Network Resource Group.')
param vnetRgp string

@description('Required. Keyvault log analytics resource id.')
param logAnalyticsResourceId string

@description('Required. Private Link Subnet Name.')
param privateLinkSubnetName string

@description('Required. Specifies the name of the ACR.')
param acrName string

@description('Required. ACR Resource Group.')
param acrRgpName string

@description('Required. Private DNS Zones Resource Group.')
param dnsZoneRgpName string

@description('Required. Private DNS Zones Resource Group Subscription Id.')
param dnsZoneRgpSubId string

@description('Required. Keyvault Name for CMK.')
param kvtName string

@description('Required. Keyvault Resource Group Name for CMK.')
param kvtRgpName string

@description('Required. Keyvault Resource Group Sub Id for CMK.')
param kvtRgpSubId string



@description('Keyvault reference')
resource keyvaultRef 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: kvtName
  scope: resourceGroup(kvtRgpSubId,kvtRgpName)
}

@description('Calculate private link subnet resource id')
resource privateLinkSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  name: '${vnetName}/${privateLinkSubnetName}'
  scope: resourceGroup(vnetRgp)
}

@description('Create user managed identity for ACR')
module acrUmi '../../carmlBicepModules/Microsoft.ManagedIdentity/userAssignedIdentities/deploy.bicep' = {
  name: 'acrUmi-${uniqueString(deployment().name)}'
  scope: resourceGroup(acrRgpName)
  params: {
    name: '${acrName}-ID'
  }
}

@description('Create customer managed keys for ACR')
module cmkKey '../../carmlBicepModules/Microsoft.KeyVault/vaults/keys/deploy.bicep' = {
  name: 'cmkkey-${uniqueString(deployment().name)}'
  scope: resourceGroup(kvtRgpSubId,kvtRgpName)
  params: {
    name: toUpper('${acrName}-CMK-01')
    keyVaultName: keyvaultRef.name
    keySize: 2048
    kty: 'RSA-HSM'
  }
}

@description('Assign the acr umi with access to the cmk in the keyvault')
module assignAcrUmiToKvt '../../carmlBicepModules/Microsoft.KeyVault/vaults/accessPolicies/deploy.bicep' = {
  name: 'assignAcrUmiToKvt-${uniqueString(deployment().name)}'
  scope: resourceGroup(kvtRgpSubId,kvtRgpName)
  params: {
    keyVaultName: kvtName
    accessPolicies: [
      {
        objectId: acrUmi.outputs.principalId
        permissions: {
          certificates: []
          keys: [
            'get'
            'wrapKey'
            'unwrapKey'
          ]
          secrets: []
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}

@description('Calculate acr Private DNS Zone resource id')
resource acrPrivateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(dnsZoneRgpSubId,dnsZoneRgpName)
  name: 'privatelink${environment().suffixes.acrLoginServer}'
}

@description('Create ACR')
module acr '../../carmlBicepModules/Microsoft.ContainerRegistry/registries/deploy.bicep' = {
  name: 'acr-${uniqueString(deployment().name)}'
  scope: resourceGroup(acrRgpName)
  params: {
    name: acrName
    cMKUserAssignedIdentityResourceId: acrUmi.outputs.resourceId
    acrSku: 'Premium'
    cMKKeyName: cmkKey.outputs.name
    cMKKeyVaultResourceId: keyvaultRef.id
    dataEndpointEnabled: true
    diagnosticWorkspaceId: logAnalyticsResourceId
    publicNetworkAccess: 'Disabled'
    userAssignedIdentities: {
      '${acrUmi.outputs.resourceId}': {}
    }
    privateEndpoints: [
      {
        name: '${acrName}-Endpoint-01'
        subnetResourceId: privateLinkSubnet.id
        privateDnsZoneGroups: [
          {
            privateDNSResourceIds: [
              acrPrivateDNSZone.id
            ]
          }
        ]
        service: 'registry'
      }
    ]
  }
}
