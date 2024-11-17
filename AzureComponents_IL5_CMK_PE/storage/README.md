# /workspaces/AzureComponents_IL5_CMK_PE/AzureComponents_IL5_CMK_PE/storage/stgDeployCarml.bicep

## Modules

| Symbolic Name | Source | Description |
| --- | --- | --- |
| assignStgUmiToKvt | ../../carmlBicepModules/Microsoft.KeyVault/vaults/accessPolicies/deploy.bicep | Assign the stg umi with access to the cmk in the keyvault |
| cmkKey | ../../carmlBicepModules/Microsoft.KeyVault/vaults/keys/deploy.bicep | Create customer managed keys for storage account |
| stg | ../../carmlBicepModules/Microsoft.Storage/storageAccounts/deploy.bicep | Create storage account |
| stgUmi | ../../carmlBicepModules/Microsoft.ManagedIdentity/userAssignedIdentities/deploy.bicep | Create user managed identity for storage account |

## Parameters

| Name | Type | Description | Default |
| --- | --- | --- | --- |
| dnsZoneRgpName | string | Required. Private DNS Zones Resource Group. |  |
| dnsZoneRgpSubId | string | Required. Private DNS Zones Resource Group Subscription Id. |  |
| kvtName | string | Required. Keyvault Name for CMK. |  |
| kvtRgpName | string | Required. Keyvault Resource Group Name for CMK. |  |
| kvtRgpSubId | string | Required. Keyvault Resource Group Sub Id for CMK. |  |
| logAnalyticsResourceId | string | Required. Keyvault log analytics resource id. |  |
| networkAcls | object | Optional. Public endpoint firewall. | {"bypass": "AzureServices", "defaultAction": "Deny", "ipRules": [], "virtualNetworkRules": []} |
| privateLinkSubnetName | string | Required. Private Link Subnet Name. |  |
| stgName | string | Required. Specifies the name of the storage account. |  |
| stgRgpName | string | Required. Storage account Resource Group. |  |
| storageAccountKind | string | Optional. Specifies the storage account kind. | "StorageV2" |
| storageAccountSku | string | Optional. Specifies the storage account SKU. | "Standard_LRS" |
| vnetName | string | Required. Virtual Network Name. |  |
| vnetRgp | string | Required. Virtual Network Resource Group. |  |

## Resources

| Symbolic Name | Type | Description |
| --- | --- | --- |
| keyvaultRef | [Microsoft.KeyVault/vaults](https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults) | Keyvault reference |
| privateLinkSubnet | [Microsoft.Network/virtualNetworks/subnets](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks/subnets) | Calculate private link subnet resource id |
| stgBlobPrivateDNSZone | [Microsoft.Network/privateDnsZones](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/privatednszones) | Calculate storage account blob Private DNS Zone resource id |
| stgFilePrivateDNSZone | [Microsoft.Network/privateDnsZones](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/privatednszones) | Calculate storage account file Private DNS Zone resource id |
