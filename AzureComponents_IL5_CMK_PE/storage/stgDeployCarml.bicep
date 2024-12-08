metadata name = 'Regulated Industry Azure Storage (STG) Deployment'
metadata description = 'Create an Azure Storage (STG) that is a private storage account deployed into a virtual network and is integrated to a Log Analytics workspace for diagnostics.'


@description('Required. Virtual Network Name.')
param vnetName string

@description('Required. Virtual Network Resource Group.')
param vnetRgp string

@description('Required. Keyvault log analytics resource id.')
param logAnalyticsResourceId string

@description('Required. Private Link Subnet Name.')
param privateLinkSubnetName string

@description('Required. Specifies the name of the storage account.')
param stgName string

@description('Required. Storage account Resource Group.')
param stgRgpName string

@description('Optional. Public endpoint firewall.')
param networkAcls object = {
  bypass: 'AzureServices'
  defaultAction: 'Deny'
  ipRules: []
  virtualNetworkRules: []
}

@description('Optional. Specifies the storage account kind.')
param storageAccountKind string = 'StorageV2'

@description('Optional. Specifies the storage account SKU.')
param storageAccountSku string = 'Standard_LRS'

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
@description('Calculate storage account file Private DNS Zone resource id')
resource stgFilePrivateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(dnsZoneRgpSubId,dnsZoneRgpName)
  name: 'privatelink.file.${environment().suffixes.storage}'
}

@description('Calculate storage account blob Private DNS Zone resource id')
resource stgBlobPrivateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(dnsZoneRgpSubId,dnsZoneRgpName)
  name: 'privatelink.blob.${environment().suffixes.storage}'
}

@description('Create user managed identity for storage account')
module stgUmi '../../carmlBicepModules/Microsoft.ManagedIdentity/userAssignedIdentities/deploy.bicep' = {
  name: 'stgUmi-${uniqueString(deployment().name)}'
  scope: resourceGroup(stgRgpName)
  params: {
    name: '${stgName}-id'
  }
}


@description('Create customer managed keys for storage account')
module cmkKey '../../carmlBicepModules/Microsoft.KeyVault/vaults/keys/deploy.bicep' = {
  name: 'cmkkey-${uniqueString(deployment().name)}'
  scope: resourceGroup(kvtRgpSubId,kvtRgpName)
  params: {
    name: toUpper('${stgName}-CMK-01')
    keyVaultName: keyvaultRef.name
    keySize: 2048
    kty: 'RSA-HSM'
  }
}

@description('Assign the stg umi with access to the cmk in the keyvault')
module assignStgUmiToKvt '../../carmlBicepModules/Microsoft.KeyVault/vaults/accessPolicies/deploy.bicep' = {
  name: 'assignStgUmiToKvt-${uniqueString(deployment().name)}'
  scope: resourceGroup(kvtRgpSubId,kvtRgpName)
  params: {
    keyVaultName: kvtName
    accessPolicies: [
      {
        objectId: stgUmi.outputs.principalId
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

@description('Create storage account')
module stg '../../carmlBicepModules/Microsoft.Storage/storageAccounts/deploy.bicep' = {
  name: 'stg-${uniqueString(deployment().name)}'
  scope: resourceGroup(stgRgpName)
  params: {
    name: stgName
    cMKUserAssignedIdentityResourceId: stgUmi.outputs.resourceId
    cMKKeyName: cmkKey.outputs.name
    cMKKeyVaultResourceId: keyvaultRef.id
    diagnosticWorkspaceId: logAnalyticsResourceId
    userAssignedIdentities: {
      '${stgUmi.outputs.resourceId}': {}
    }
    networkAcls: networkAcls
    storageAccountKind: storageAccountKind
    storageAccountSku: storageAccountSku
    privateEndpoints: [
      {
        name: '${stgName}-file-endpoint-01'
        subnetResourceId: privateLinkSubnet.id
        privateDnsZoneGroups: [
          {
            privateDNSResourceIds: [
              stgFilePrivateDNSZone.id
            ]
          }
        ]
        service: 'file'
      }
      {
        name: '${stgName}-blob-endpoint-01'
        subnetResourceId: privateLinkSubnet.id
        privateDnsZoneGroups: [
          {
            privateDNSResourceIds: [
              stgBlobPrivateDNSZone.id
            ]
          }
        ]
        service: 'blob'
      }
    ]
  }
}
