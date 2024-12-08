/*
Pre-reqs:
- Virtual networks
- Resource Groups
- Private DNS Zones for Storage Account File Shares/Blobs, Keyvault, ACR, and AKS
- Keyvault

What is Deployed:
- User Managed Identities
- Customer Managed Keys
- Disk Encryption Sets
- Storage Account with Private Endpoint, using CMK, and File Shares
- Acr with Private Endpoint, using CMK
- Aks Private Cluster using Disk Encryption Set with Configurable Node Pools
*/

metadata name = 'Regulated Industry Azure Kubernetes Service (AKS) Deployment'
metadata description = 'Create an Azure Kubernetes Service (AKS) that is a private cluster using a customer managed key, private endpoint, and private DNS zone for regulated industries'

@description('Optional. Project name for naming')
param prj string = 'tst'

@description('Optional. IL of resources for naming.')
param il string = 'il5'

@description('Optional. Location for the resources to be deployed to.')
param location string = resourceGroup().location

@description('Required. Virtual Network Name.')
param vnetName string

@description('Required. Virtual Network Resource Group.')
param vnetRgp string

@description('Required. Log analytics resource id.')
param logAnalyticsResourceId string

@description('Required. Private Link Subnet Name.')
param privateLinkSubnetName string

@description('Required. Keyvault Name.')
param kvtName string

@description('Required.. Primary Resource Group.')
param priRgpName string

@description('Required. Private DNS Zones Resource Group.')
param dnsZoneRgpName string

@description('Required. Private DNS Zones Resource Group Subscription Id.')
param dnsZoneRgpSubId string

@description('Optional. Adds customer managed key and DES for each array member - For AKS and managed disks')
param cmkDESRoles array = [
  'aks'
]

@description('Optional. The array ID of the cmkDESRoles array to use for the aks DES.')
param aksCmkDESRolesArrayID int = 0

@description('Optional. Specifies the name of the ACR.')
param acrName string = toLower('${prj}${il}acr')

@description('Optional. Specifies the name of the storage account.')
param stgName string = toLower('${prj}${il}stg')

@description('Optional. Specifies the storage account kind.')
param storageAccountKind string = 'StorageV2'

@description('Optional. Specifies the storage account SKU.')
param storageAccountSku string = 'Standard_LRS'

@description('Optional. Specifies the name of the file shares on the storage account.')
param fileShares array = [
]

@description('Optional. Specifies the name of the AKS cluster.')
param aksClusterName string = toLower('${prj}-${il}-AKS')

@description('Optional. Specifies the network plugin used for building Kubernetes network. - azure or kubenet.')
param aksClusterNetworkPlugin string = 'azure'

@description('Optional. Specifies the network policy used for building Kubernetes network. - calico or azure')
param aksClusterNetworkPolicy string = 'azure'

@description('Optional. Specifies the CIDR notation IP range from which to assign pod IPs when kubenet is used.')
param aksClusterServiceCidr string = '10.100.0.0/16'

@description('Optional. Specifies the IP address assigned to the Kubernetes DNS service. It must be within the Kubernetes service address range specified in serviceCidr.')
param aksClusterDnsServiceIP string = '10.100.0.10'

@description('Optional. Specifies the CIDR notation IP range assigned to the Docker bridge network. It must not overlap with any Subnet IP ranges or the Kubernetes service address range.')
param aksClusterDockerBridgeCidr string = '172.17.0.1/16'

@description('Optional. Tier of a managed cluster SKU. - Free or Paid')
param aksClusterSkuTier string = 'Paid'

@description('Optional. Version of Kubernetes specified when creating the managed cluster.')
param aksClusterKubernetesVersion string = '1.22.4'

@description('Optional. Specifies the AAD group object IDs that will have admin role of the cluster.')
param aadProfileAdminGroupObjectIDs array

@description('Optional. The Private DNS Zone ID that is used for AKSs Private Dns Zone')
param aksPrivateDNSZoneId string

@description('Optional. Specifies whether to enable managed AAD integration.')
param aadProfileManaged bool = true

@description('Optional. Specifies whether to enable Azure RBAC for Kubernetes authorization.')
param aadProfileEnableAzureRBAC bool = true

@description('Optional. If set to true, getting static credentials will be disabled for this cluster. This must only be used on Managed Clusters that are AAD enabled.')
param disableLocalAccounts bool = true

@description('Optional. Name of the resource group containing agent pool nodes.')
param nodeResourceGroup string = 'AKS-NODE-01'

@description('Optional. Specifies whether to create the cluster as a private cluster or not.')
param enablePrivateCluster bool = true

@description('Required. Properties of the primary agent pool.')
param primaryAgentPoolProfile array

@description('Optional. Define one or more secondary/additional agent pools')
param agentPools array = []

@description('Optional. Specifies whether the KeyvaultSecretsProvider add-on is enabled or not.')
param enableKeyvaultSecretsProvider bool = true

@allowed([
  'false'
  'true'
])
@description('Optional. Specifies whether the KeyvaultSecretsProvider add-on uses secret rotation.')
param enableSecretRotation string = 'true'

@description('Optional. Whether to enable Azure Defender.')
param enableAzureDefender bool = false

@description('Optional. Outbound IP Count for the Load balancer.')
param managedOutboundIPCount int = 1

@description('Optional. Public endpoint firewall.')
var networkAcls = {
  bypass: 'AzureServices'
  defaultAction: 'Deny'
  ipRules: []
  virtualNetworkRules: []
}

@description('The default role assignment guid for privateDnsZoneContributor')
var privateDnsZoneContributorGuid = 'b12aa53e-6015-4669-85d0-8515ebb3ae7f'

@description('The default role assignment guid for Network Contributor')
var networkContributorGuid = '4d97b98b-1d4f-4787-a291-c67834d212e7'

@description('The default role assignment guid for Reader')
var readerGuid = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

@description('Generate an Azure Resource Manager (ARM) reference to the Azure Subnet that will be used to map the Azure Kubernetes Service (AKS) private interface to the appropriate subnet.')
resource privateLinkSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  name: '${vnetName}/${privateLinkSubnetName}'
  scope: resourceGroup(vnetRgp)
}

@description('Generate an Azure Resource Manager (ARM) reference to the Azure Key Vault (AKV)  that will be used to create the customer managed key (CMK) for the Azure Kubernetes Service (AKS).')
resource keyvaultRef 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: kvtName
  scope: resourceGroup(priRgpName)
}

@description('Create customer managed keys for the Azure Container Registry (ACR) that will be used to encrypt the data at rest. To meet Impact Level 5 requirements we will assign a key size of 4096 bits and use the RSA-HSM key type.')
module cmkKey '../../carmlBicepModules/Microsoft.KeyVault/vaults/keys/deploy.bicep' = [for role in cmkDESRoles: {
  name: 'cmkkey-${role}-${uniqueString(deployment().name)}'
  scope: resourceGroup(priRgpName)
  params: {
    name: toLower('${prj}-${il}-${role}-CMK')
    keyVaultName: keyvaultRef.name
    keySize: 4096
    kty: 'RSA-HSM'
  }
}]

@description('Creates disk encryption sets associated with customer managed keys for each array member')
module des '../../carmlBicepModules/Microsoft.Compute/diskEncryptionSets/deploy.bicep' = [for (role, i) in cmkDESRoles: {
  name: 'des-${role}-${uniqueString(deployment().name)}'
  scope: resourceGroup(priRgpName)
  params: {
    name: toLower('${prj}-${il}-${role}-DES')
    keyUrl: cmkKey[i].outputs.keyURIWithVersion
    keyVaultId: keyvaultRef.id
    rotationToLatestKeyVersionEnabled: true
  }
}]

@description('Create user managed identity for the Azure Kubernetes Service (AKS) to authenticate against the Azure Key Vault to retrieve the customer managed key.')
module aksUmi '../../carmlBicepModules/Microsoft.ManagedIdentity/userAssignedIdentities/deploy.bicep' = {
  name: 'aksumi-${uniqueString(deployment().name)}'
  scope: resourceGroup(priRgpName)
  params: {
    name: '${aksClusterName}-id'
  }
}

@description('Assign the Azure Kubernetes Service (AKS) User Managed Identity (UMI) as a privateDnsZoneContributor on the Private DNS Zone Resource Group')
module assignAksUmiToPrivateDnsZoneResourceGroup '../../bicepModules/Identity/role.bicep' = {
  name: 'assign-umi-to-dnsZone-${uniqueString(deployment().name)}'
  scope: resourceGroup(dnsZoneRgpSubId,dnsZoneRgpName)
  params: {
    principalId: aksUmi.outputs.principalId
    roleGuid: privateDnsZoneContributorGuid
    name: guid(aksUmi.outputs.principalId, privateDnsZoneContributorGuid) // GUID created from parameters that allows rerun
  }
}

@description('Assign the Azure Kubernetes Service (AKS) User Managed Identity (UMI) as a Network Contributor on the Resource Group that owns the Virtual Network')
module assignNetworkContributor '../../bicepModules/Identity/role.bicep' = {
  name: 'assign-umi-to-vnetrgp-${uniqueString(deployment().name)}'
  scope: resourceGroup(vnetRgp)
  params: {
    principalId: aksUmi.outputs.principalId
    roleGuid: networkContributorGuid
    name: guid(aksUmi.outputs.principalId, networkContributorGuid) // GUID created from parameters that allows rerun
  }
}

@description('Assign the Azure Kubernetes Service (AKS) User Managed Identity (UMI) as a reader in its own resource group')
module assignAksUmiAsReaderOnItsResourceGroup '../../bicepModules/Identity/role.bicep' = {
  name: 'assign-umi-to-aksRgp-${uniqueString(deployment().name)}'
  scope: resourceGroup(priRgpName)
  params: {
    principalId: aksUmi.outputs.principalId
    roleGuid: readerGuid
    name: guid('${aksUmi.outputs.principalId}', readerGuid) // GUID created from parameters that allows rerun
  }
}

@description('Create the Azure Kubernetes Service Private Cluster on the targeted virtual network')
module aks '../../carmlBicepModules/Microsoft.ContainerService/managedClusters/deploy.bicep' = {
  name: 'aks-${uniqueString(deployment().name)}'
  scope: resourceGroup(priRgpName)
  params: {
    name: aksClusterName
    location: location
    aksClusterNetworkPolicy: aksClusterNetworkPolicy
    aksClusterNetworkPlugin: aksClusterNetworkPlugin
    aksClusterServiceCidr: aksClusterServiceCidr
    aksClusterDnsServiceIP: aksClusterDnsServiceIP
    aksClusterDockerBridgeCidr: aksClusterDockerBridgeCidr
    aksClusterSkuTier: aksClusterSkuTier
    aksClusterKubernetesVersion: aksClusterKubernetesVersion
    aadProfileManaged: aadProfileManaged
    aadProfileAdminGroupObjectIDs: aadProfileAdminGroupObjectIDs
    aadProfileEnableAzureRBAC: aadProfileEnableAzureRBAC
    disableLocalAccounts: disableLocalAccounts
    nodeResourceGroup: nodeResourceGroup
    enablePrivateCluster: enablePrivateCluster
    privateDNSZoneId: aksPrivateDNSZoneId
    primaryAgentPoolProfile: primaryAgentPoolProfile
    agentPools: agentPools
    enableKeyvaultSecretsProvider: enableKeyvaultSecretsProvider
    enableSecretRotation: enableSecretRotation
    enableAzureDefender: enableAzureDefender
    managedOutboundIPCount: managedOutboundIPCount
    monitoringWorkspaceId: logAnalyticsResourceId
    userAssignedIdentities: {
      '${aksUmi.outputs.resourceId}': {}
    }
    diskEncryptionSetID: des[aksCmkDESRolesArrayID].outputs.resourceId
  }
}

@description('Create user managed identity for the Azure Container Registry (ACR) to authenticate against the Azure Key Vault to retrieve the customer managed key.')
module acrUmi '../../carmlBicepModules/Microsoft.ManagedIdentity/userAssignedIdentities/deploy.bicep' = {
  name: 'acrUmi-${uniqueString(deployment().name)}'
  scope: resourceGroup(priRgpName)
  params: {
    name: '${acrName}-ID'
  }
}

@description('Assign the Azure Container Registry (ACR) User Managed Identity (UMI) with the required key vault access policy to pull the Azure Key Vault (AKV) hosted encryption key.')
module assignAcrUmiToKvt '../../carmlBicepModules/Microsoft.KeyVault/vaults/accessPolicies/deploy.bicep' = {
  name: 'assignAcrUmiToKvt-${uniqueString(deployment().name)}'
  scope: resourceGroup(priRgpName)
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
  scope: resourceGroup(priRgpName)
  params: {
    name: acrName
    cMKUserAssignedIdentityResourceId: acrUmi.outputs.resourceId
    acrSku: 'Premium'
    cMKKeyName: cmkKey[aksCmkDESRolesArrayID].outputs.name
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
  dependsOn: [
    assignAcrUmiToKvt
  ]
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
  scope: resourceGroup(priRgpName)
  params: {
    name: '${stgName}-id'
  }
}

@description('Assign the stg umi with access to the cmk in the keyvault')
module assignStgUmiToKvt '../../carmlBicepModules/Microsoft.KeyVault/vaults/accessPolicies/deploy.bicep' = {
  name: 'assignStgUmiToKvt-${uniqueString(deployment().name)}'
  scope: resourceGroup(priRgpName)
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
  scope: resourceGroup(priRgpName)
  params: {
    name: stgName
    cMKUserAssignedIdentityResourceId: stgUmi.outputs.resourceId
    cMKKeyName: cmkKey[aksCmkDESRolesArrayID].outputs.name
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
  dependsOn: [
    assignStgUmiToKvt
  ]
}

@description('Create shares')
module stgShares '../../carmlBicepModules/Microsoft.Storage/storageAccounts/fileServices/shares/deploy.bicep' = [for share in fileShares: {
  name: 'stg-${share}-${uniqueString(deployment().name)}'
  scope: resourceGroup(priRgpName)
  params: {
    name: share
    storageAccountName: stg.outputs.name
  }
}]
