# acrDeployCarml.bicep

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

## Modules

| Symbolic Name | Source | Description |
| --- | --- | --- |
| acr | ../../carmlBicepModules/Microsoft.ContainerRegistry/registries/deploy.bicep | Create Azure Container Registry using the generated user managed identity, customer managed key, and private link. |
| acrUmi | ../../carmlBicepModules/Microsoft.ManagedIdentity/userAssignedIdentities/deploy.bicep | Deploy a user-managed identity for Azure Container Registry (ACR). |
| assignAcrUmiToKvt | ../../carmlBicepModules/Microsoft.KeyVault/vaults/accessPolicies/deploy.bicep | Assign the acr umi with access to the cmk in the keyvault |
| cmkKey | ../../carmlBicepModules/Microsoft.KeyVault/vaults/keys/deploy.bicep | Create customer managed keys for ACR |

## Resources

| Symbolic Name | Type | Description |
| --- | --- | --- |
| acrPrivateDNSZone | [Microsoft.Network/privateDnsZones](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/privatednszones) | Calculate acr Private DNS Zone resource id |
| keyvaultRef | [Microsoft.KeyVault/vaults](https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults) | Reference to the existing Key Vault resource. |
| privateLinkSubnet | [Microsoft.Network/virtualNetworks/subnets](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks/subnets) | Reference to the existing subnet within the virtual network for private link. |

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
