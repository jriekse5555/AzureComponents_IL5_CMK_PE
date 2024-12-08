# Regulated Industry Azure Kubernetes Service (AKS) Deployment

## Description

Create an Azure Kubernetes Service (AKS) that is a private cluster using a customer managed key, private endpoint, and private DNS zone for regulated industries

## Modules

| Symbolic Name | Source | Description |
| --- | --- | --- |
| acr | ../../carmlBicepModules/Microsoft.ContainerRegistry/registries/deploy.bicep | Create the Azure Container Registry using the previously created resources. This will create the Azure Container Registry (ACR) with a key vault reference and use the private dns zone scope to create a new "A" Record in the zone for this container registry. |
| acrUmi | ../../carmlBicepModules/Microsoft.ManagedIdentity/userAssignedIdentities/deploy.bicep | Create user managed identity for the Azure Container Registry (ACR) to authenticate against the Azure Key Vault to retrieve the customer managed key. |
| aks | ../../carmlBicepModules/Microsoft.ContainerService/managedClusters/deploy.bicep | Create the Azure Kubernetes Service Private Cluster on the targeted virtual network |
| aksUmi | ../../carmlBicepModules/Microsoft.ManagedIdentity/userAssignedIdentities/deploy.bicep | Create user managed identity for the Azure Kubernetes Service (AKS) to authenticate against the Azure Key Vault to retrieve the customer managed key. |
| assignAcrUmiToKvt | ../../carmlBicepModules/Microsoft.KeyVault/vaults/accessPolicies/deploy.bicep | Assign the Azure Container Registry (ACR) User Managed Identity (UMI) with the required key vault access policy to pull the Azure Key Vault (AKV) hosted encryption key. |
| assignAksUmiAsReaderOnItsResourceGroup | ../../bicepModules/Identity/role.bicep | Assign the Azure Kubernetes Service (AKS) User Managed Identity (UMI) as a reader in its own resource group |
| assignAksUmiToPrivateDnsZoneResourceGroup | ../../bicepModules/Identity/role.bicep | Assign the Azure Kubernetes Service (AKS) User Managed Identity (UMI) as a privateDnsZoneContributor on the Private DNS Zone Resource Group |
| assignNetworkContributor | ../../bicepModules/Identity/role.bicep | Assign the Azure Kubernetes Service (AKS) User Managed Identity (UMI) as a Network Contributor on the Resource Group that owns the Virtual Network |
| assignStgUmiToKvt | ../../carmlBicepModules/Microsoft.KeyVault/vaults/accessPolicies/deploy.bicep | Assign the stg umi with access to the cmk in the keyvault |
| cmkKey | ../../carmlBicepModules/Microsoft.KeyVault/vaults/keys/deploy.bicep | Create customer managed keys for the Azure Container Registry (ACR) that will be used to encrypt the data at rest. To meet Impact Level 5 requirements we will assign a key size of 4096 bits and use the RSA-HSM key type. |
| des | ../../carmlBicepModules/Microsoft.Compute/diskEncryptionSets/deploy.bicep | Creates disk encryption sets associated with customer managed keys for each array member |
| stg | ../../carmlBicepModules/Microsoft.Storage/storageAccounts/deploy.bicep | Create storage account |
| stgShares | ../../carmlBicepModules/Microsoft.Storage/storageAccounts/fileServices/shares/deploy.bicep | Create shares |
| stgUmi | ../../carmlBicepModules/Microsoft.ManagedIdentity/userAssignedIdentities/deploy.bicep | Create user managed identity for storage account |

## Parameters

| Name | Type | Description | Default |
| --- | --- | --- | --- |
| aadProfileAdminGroupObjectIDs | array | Optional. Specifies the AAD group object IDs that will have admin role of the cluster. |  |
| aadProfileEnableAzureRBAC | bool | Optional. Specifies whether to enable Azure RBAC for Kubernetes authorization. | true |
| aadProfileManaged | bool | Optional. Specifies whether to enable managed AAD integration. | true |
| acrName | string | Optional. Specifies the name of the ACR. | "[toLower(format('{0}{1}acr', parameters('prj'), parameters('il')))]" |
| agentPools | array | Optional. Define one or more secondary/additional agent pools | [] |
| aksClusterDnsServiceIP | string | Optional. Specifies the IP address assigned to the Kubernetes DNS service. It must be within the Kubernetes service address range specified in serviceCidr. | "10.100.0.10" |
| aksClusterDockerBridgeCidr | string | Optional. Specifies the CIDR notation IP range assigned to the Docker bridge network. It must not overlap with any Subnet IP ranges or the Kubernetes service address range. | "172.17.0.1/16" |
| aksClusterKubernetesVersion | string | Optional. Version of Kubernetes specified when creating the managed cluster. | "1.22.4" |
| aksClusterName | string | Optional. Specifies the name of the AKS cluster. | "[toLower(format('{0}-{1}-AKS', parameters('prj'), parameters('il')))]" |
| aksClusterNetworkPlugin | string | Optional. Specifies the network plugin used for building Kubernetes network. - azure or kubenet. | "azure" |
| aksClusterNetworkPolicy | string | Optional. Specifies the network policy used for building Kubernetes network. - calico or azure | "azure" |
| aksClusterServiceCidr | string | Optional. Specifies the CIDR notation IP range from which to assign pod IPs when kubenet is used. | "10.100.0.0/16" |
| aksClusterSkuTier | string | Optional. Tier of a managed cluster SKU. - Free or Paid | "Paid" |
| aksCmkDESRolesArrayID | int | Optional. The array ID of the cmkDESRoles array to use for the aks DES. | 0 |
| aksPrivateDNSZoneId | string | Optional. The Private DNS Zone ID that is used for AKSs Private Dns Zone |  |
| cmkDESRoles | array | Optional. Adds customer managed key and DES for each array member - For AKS and managed disks | ["aks"] |
| disableLocalAccounts | bool | Optional. If set to true, getting static credentials will be disabled for this cluster. This must only be used on Managed Clusters that are AAD enabled. | true |
| dnsZoneRgpName | string | Required. Private DNS Zones Resource Group. |  |
| dnsZoneRgpSubId | string | Required. Private DNS Zones Resource Group Subscription Id. |  |
| enableAzureDefender | bool | Optional. Whether to enable Azure Defender. | false |
| enableKeyvaultSecretsProvider | bool | Optional. Specifies whether the KeyvaultSecretsProvider add-on is enabled or not. | true |
| enablePrivateCluster | bool | Optional. Specifies whether to create the cluster as a private cluster or not. | true |
| enableSecretRotation | string | Optional. Specifies whether the KeyvaultSecretsProvider add-on uses secret rotation. | "true" |
| fileShares | array | Optional. Specifies the name of the file shares on the storage account. | [] |
| il | string | Optional. IL of resources for naming. | "il5" |
| kvtName | string | Required. Keyvault Name. |  |
| location | string | Optional. Location for the resources to be deployed to. | "[resourceGroup().location]" |
| logAnalyticsResourceId | string | Required. Log analytics resource id. |  |
| managedOutboundIPCount | int | Optional. Outbound IP Count for the Load balancer. | 1 |
| nodeResourceGroup | string | Optional. Name of the resource group containing agent pool nodes. | "AKS-NODE-01" |
| priRgpName | string | Required.. Primary Resource Group. |  |
| primaryAgentPoolProfile | array | Required. Properties of the primary agent pool. |  |
| privateLinkSubnetName | string | Required. Private Link Subnet Name. |  |
| prj | string | Optional. Project name for naming | "tst" |
| stgName | string | Optional. Specifies the name of the storage account. | "[toLower(format('{0}{1}stg', parameters('prj'), parameters('il')))]" |
| storageAccountKind | string | Optional. Specifies the storage account kind. | "StorageV2" |
| storageAccountSku | string | Optional. Specifies the storage account SKU. | "Standard_LRS" |
| vnetName | string | Required. Virtual Network Name. |  |
| vnetRgp | string | Required. Virtual Network Resource Group. |  |

## Resources

| Symbolic Name | Type | Description |
| --- | --- | --- |
| acrPrivateDNSZone | [Microsoft.Network/privateDnsZones](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/privatednszones) | Generate an Azure Resource Manager (ARM) reference to the Azure Container Registry (ACR) Private DNS Zone that will be used to resolve the ACR private endpoint. |
| keyvaultRef | [Microsoft.KeyVault/vaults](https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults) | Generate an Azure Resource Manager (ARM) reference to the Azure Key Vault (AKV)  that will be used to create the customer managed key (CMK) for the Azure Kubernetes Service (AKS). |
| privateLinkSubnet | [Microsoft.Network/virtualNetworks/subnets](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks/subnets) | Generate an Azure Resource Manager (ARM) reference to the Azure Subnet that will be used to map the Azure Kubernetes Service (AKS) private interface to the appropriate subnet. |
| stgBlobPrivateDNSZone | [Microsoft.Network/privateDnsZones](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/privatednszones) | Calculate storage account blob Private DNS Zone resource id |
| stgFilePrivateDNSZone | [Microsoft.Network/privateDnsZones](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/privatednszones) | Calculate storage account file Private DNS Zone resource id |

## Variables

| Name | Description |
| --- | --- |
| networkAcls | Optional. Public endpoint firewall. |
| networkContributorGuid |  |
| privateDnsZoneContributorGuid |  |
| readerGuid | The default role assignment guid for Reader |

## Usage

Here is a basic example of how to use this Bicep module:

```bicep
module reference_name 'path_to_module | container_registry_reference' = {
  name: 'deployment_name'
  params: {
    // Required parameters
    aadProfileAdminGroupObjectIDs:
    aksPrivateDNSZoneId:
    dnsZoneRgpName:
    dnsZoneRgpSubId:
    kvtName:
    logAnalyticsResourceId:
    priRgpName:
    primaryAgentPoolProfile:
    privateLinkSubnetName:
    vnetName:
    vnetRgp:

    // Optional parameters
    aadProfileEnableAzureRBAC: true
    aadProfileManaged: true
    acrName: '[toLower(format('{0}{1}acr' parameters('prj') parameters('il')))]'
    agentPools: []
    aksClusterDnsServiceIP: '10.100.0.10'
    aksClusterDockerBridgeCidr: '172.17.0.1/16'
    aksClusterKubernetesVersion: '1.22.4'
    aksClusterName: '[toLower(format('{0}-{1}-AKS' parameters('prj') parameters('il')))]'
    aksClusterNetworkPlugin: 'azure'
    aksClusterNetworkPolicy: 'azure'
    aksClusterServiceCidr: '10.100.0.0/16'
    aksClusterSkuTier: 'Paid'
    aksCmkDESRolesArrayID: 0
    cmkDESRoles: [
      'aks'
    ]
    disableLocalAccounts: true
    enableAzureDefender: false
    enableKeyvaultSecretsProvider: true
    enablePrivateCluster: true
    enableSecretRotation: 'true'
    fileShares: []
    il: 'il5'
    location: '[resourceGroup().location]'
    managedOutboundIPCount: 1
    nodeResourceGroup: 'AKS-NODE-01'
    prj: 'tst'
    stgName: '[toLower(format('{0}{1}stg' parameters('prj') parameters('il')))]'
    storageAccountKind: 'StorageV2'
    storageAccountSku: 'Standard_LRS'
  }
}
```

> Note: In the default values, strings enclosed in square brackets (e.g. '[resourceGroup().location]' or '[__bicep.function_name(args...)']) represent function calls or references.
