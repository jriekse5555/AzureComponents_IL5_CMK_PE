metadata name = 'Regulated Industry Azure Container Registry (ACR) Deployment'
metadata description = 'Create an Azure Container Registry (ACR) using a customer managed key, private endpoint, and private DNS zone for regulated industries'

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



@description('Generate an Azure Resource Manager (ARM) reference to the Azure Key Vault (AKV)  that will be used to create the customer managed key (CMK) for the Azure Container Registry (ACR).')
resource keyvaultRef 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: kvtName
  scope: resourceGroup(kvtRgpSubId,kvtRgpName)
}

@description('Generate an Azure Resource Manager (ARM) reference to the Azure Subnet that will be used to map the Azure Container Registry (ACR) private interface to the appropriate subnet.')
resource privateLinkSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  name: '${vnetName}/${privateLinkSubnetName}'
  scope: resourceGroup(vnetRgp)
}

@description('Create user managed identity for the Azure Container Registry (ACR) to authenticate against the Azure Key Vault to retrieve the customer managed key.')
module acrUmi '../../carmlBicepModules/Microsoft.ManagedIdentity/userAssignedIdentities/deploy.bicep' = {
  name: 'acrUmi-${uniqueString(deployment().name)}'
  scope: resourceGroup(acrRgpName)
  params: {
    name: '${acrName}-ID'
  }
}

@description('Create customer managed keys for the Azure Container Registry (ACR) that will be used to encrypt the data at rest. To meet Impact Level 5 requirements we will assign a key size of 4096 bits and use the RSA-HSM key type.')
module cmkKey '../../carmlBicepModules/Microsoft.KeyVault/vaults/keys/deploy.bicep' = {
  name: 'cmkkey-${uniqueString(deployment().name)}'
  scope: resourceGroup(kvtRgpSubId,kvtRgpName)
  params: {
    name: toUpper('${acrName}-CMK-01')
    keyVaultName: keyvaultRef.name
    keySize: 4096
    kty: 'RSA-HSM'
  }
}

@description('Assign the Azure Container Registry (ACR) User Managed Identity (UMI) with the required key vault access policy to pull the Azure Key Vault (AKV) hosted encryption key.')
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

@description('Generate an Azure Resource Manager (ARM) reference to the Azure Container Registry (ACR) Private DNS Zone that will be used to resolve the ACR private endpoint.')
resource acrPrivateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(dnsZoneRgpSubId,dnsZoneRgpName)
  name: 'privatelink${environment().suffixes.acrLoginServer}'
}

@description('Create the Azure Container Registry using the previously created resources. This will create the Azure Container Registry (ACR) with a key vault reference and use the private dns zone scope to create a new "A" Record in the zone for this container registry.')
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
