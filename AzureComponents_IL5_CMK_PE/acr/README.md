# /workspaces/AzureComponents_IL5_CMK_PE/AzureComponents_IL5_CMK_PE/acr/acrDeployCarml.bicep

## Modules

| Symbolic Name | Source | Description |
| --- | --- | --- |
| acr | ../../carmlBicepModules/Microsoft.ContainerRegistry/registries/deploy.bicep | Create ACR |
| acrUmi | ../../carmlBicepModules/Microsoft.ManagedIdentity/userAssignedIdentities/deploy.bicep | Create user managed identity for ACR |
| assignAcrUmiToKvt | ../../carmlBicepModules/Microsoft.KeyVault/vaults/accessPolicies/deploy.bicep | Assign the acr umi with access to the cmk in the keyvault |
| cmkKey | ../../carmlBicepModules/Microsoft.KeyVault/vaults/keys/deploy.bicep | Create customer managed keys for ACR |

## Resources

| Symbolic Name | Type | Description |
| --- | --- | --- |
| acrPrivateDNSZone | [Microsoft.Network/privateDnsZones](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/privatednszones) | Calculate acr Private DNS Zone resource id |
| keyvaultRef | [Microsoft.KeyVault/vaults](https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults) | Keyvault reference |
| privateLinkSubnet | [Microsoft.Network/virtualNetworks/subnets](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks/subnets) | Calculate private link subnet resource id |

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
