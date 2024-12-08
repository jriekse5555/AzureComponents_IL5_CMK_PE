# Regulated Industry Azure Container Registry (ACR) Deployment

## Description

Create an Azure Container Registry (ACR) using a customer managed key, private endpoint, and private DNS zone for regulated industries

## Modules

| Symbolic Name | Source | Description |
| --- | --- | --- |
| acr | ../../carmlBicepModules/Microsoft.ContainerRegistry/registries/deploy.bicep | Create the Azure Container Registry using the previously created resources. This will create the Azure Container Registry (ACR) with a key vault reference and use the private dns zone scope to create a new "A" Record in the zone for this container registry. |
| acrUmi | ../../carmlBicepModules/Microsoft.ManagedIdentity/userAssignedIdentities/deploy.bicep | Create user managed identity for the Azure Container Registry (ACR) to authenticate against the Azure Key Vault to retrieve the customer managed key. |
| assignAcrUmiToKvt | ../../carmlBicepModules/Microsoft.KeyVault/vaults/accessPolicies/deploy.bicep | Assign the Azure Container Registry (ACR) User Managed Identity (UMI) with the required key vault access policy to pull the Azure Key Vault (AKV) hosted encryption key. |
| cmkKey | ../../carmlBicepModules/Microsoft.KeyVault/vaults/keys/deploy.bicep | Create customer managed keys for the Azure Container Registry (ACR) that will be used to encrypt the data at rest. To meet Impact Level 5 requirements we will assign a key size of 4096 bits and use the RSA-HSM key type. |

## Parameters

| Name | Type | Description | Default |
| --- | --- | --- | --- |
| acrName | string | Required. Specifies the name of the ACR. |  |
| acrRgpName | string | Required. ACR Resource Group. |  |
| dnsZoneRgpName | string | Required. Private DNS Zones Resource Group. |  |
| dnsZoneRgpSubId | string | Required. Private DNS Zones Resource Group Subscription Id. |  |
| kvtName | string | Required. Keyvault Name for CMK. |  |
| kvtRgpName | string | Required. Keyvault Resource Group Name for CMK. |  |
| kvtRgpSubId | string | Required. Keyvault Resource Group Sub Id for CMK. |  |
| logAnalyticsResourceId | string | Required. Keyvault log analytics resource id. |  |
| privateLinkSubnetName | string | Required. Private Link Subnet Name. |  |
| vnetName | string | Required. Virtual Network Name. |  |
| vnetRgp | string | Required. Virtual Network Resource Group. |  |

## Resources

| Symbolic Name | Type | Description |
| --- | --- | --- |
| acrPrivateDNSZone | [Microsoft.Network/privateDnsZones](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/privatednszones) | Generate an Azure Resource Manager (ARM) reference to the Azure Container Registry (ACR) Private DNS Zone that will be used to resolve the ACR private endpoint. |
| keyvaultRef | [Microsoft.KeyVault/vaults](https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults) | Generate an Azure Resource Manager (ARM) reference to the Azure Key Vault (AKV)  that will be used to create the customer managed key (CMK) for the Azure Container Registry (ACR). |
| privateLinkSubnet | [Microsoft.Network/virtualNetworks/subnets](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks/subnets) | Generate an Azure Resource Manager (ARM) reference to the Azure Subnet that will be used to map the Azure Container Registry (ACR) private interface to the appropriate subnet. |

## Usage

Here is a basic example of how to use this Bicep module:

```bicep
module reference_name 'path_to_module | container_registry_reference' = {
  name: 'deployment_name'
  params: {
    // Required parameters
    acrName:
    acrRgpName:
    dnsZoneRgpName:
    dnsZoneRgpSubId:
    kvtName:
    kvtRgpName:
    kvtRgpSubId:
    logAnalyticsResourceId:
    privateLinkSubnetName:
    vnetName:
    vnetRgp:

    // Optional parameters
  }
}
```

> Note: In the default values, strings enclosed in square brackets (e.g. '[resourceGroup().location]' or '[__bicep.function_name(args...)']) represent function calls or references.
