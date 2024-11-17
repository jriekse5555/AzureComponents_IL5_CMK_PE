# /workspaces/AzureComponents_IL5_CMK_PE/AzureComponents_IL5_CMK_PE/keyvault/kvtDeployCarml.bicep

## Modules

| Symbolic Name | Source | Description |
| --- | --- | --- |
| keyvault | ../../carmlBicepModules/Microsoft.KeyVault/vaults/deploy.bicep | Creates keyvault |

## Parameters

| Name | Type | Description | Default |
| --- | --- | --- | --- |
| enablePurgeProtection | bool | Optional. Purge protection required to store cmks. | true |
| kvtAadObjId | string | Required. Azure AD group object ID to grant full access to keyvault |  |
| kvtName | string | Optional. Keyvault Name. |  |
| kvtPrivateDNSZoneResourceId | string | Required. Keyvault private dns zone resource id. |  |
| kvtRgpName | string | Optional. Keyvault Resource Group. |  |
| location | string | Optional. Location for the resources to be deployed to. | "[resourceGroup().location]" |
| logAnalyticsResourceId | string | Required. Keyvault log analytics resource id. |  |
| networkAcls | object | Optional. Public endpoint firewall. | {"bypass": "AzureServices", "defaultAction": "Deny", "ipRules": [], "virtualNetworkRules": []} |
| privateLinkSubnetName | string | Required. Private Link Subnet Name. |  |
| vnetName | string | Optional. Virtual Network Name. |  |
| vnetRgp | string | Optional. Virtual Network Resource Group. |  |

## Resources

| Symbolic Name | Type | Description |
| --- | --- | --- |
| privateLinkSubnet | [Microsoft.Network/virtualNetworks/subnets](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks/subnets) | Calculate private link subnet resource id |

## Variables

| Name | Description |
| --- | --- |
| accessPolicies | Provides full control to Azure AD group |
