# AzureComponents_IL5_CMK_PE

Based on Bicep CARML modules which are hosted on the following github repo: https://github.com/Azure/ResourceModules

This repo provides fast deployment of the following components with Azure configuration fitting into IL5 compliance requirements by leveraging customer managed keys (CMK) (provisioned in a keyvault) and private endpoints (leveraging associated private dns zones):

- Keyvault
- Storage
- Azure Container Registry
- AKS (Note Azure Dedicated Hosts are not supported with AKS)

Prequisites for use are:
- Existing virtual network
- Existing subnet large enough to hold AKS node pools (30 IPs per node is the set default)
- Existing subnet with private endpoint policies disable to allow addition of private endpoints
- Existing Private DNS Zone for objects deployed (AKS, Storage (File/Blob), Keyvault, ACR)
- Storage and ACR require the keyvault is deployed first (to hold the CMK)

To deploy, Azure DevOps Server/Services .yml pipelines and associated .bicep files containing all the security components are within this repo. If you don't have Azure DevOps available, you can leverage the Azure CLI commands within them directly.

Copy of CARML modules made for simpicity around 7/1/2022 with slight refinements made for the following modules:

- AKS (to enable Disk Encryption Set linked to CMK AND central AKS private DNS zone)
- Keyvault\Keys - Added an output to support DES (Latest DES module no longer needs this)

Numerous improvements are made to the central CARML repo on a recurring basis so its recommended that you evaluate the latest module versions as needed. The copy is leveraged to ensure highest compatibility. There are also several CARML versioning methods that can be used instead if all your environments support this and you are interested in more dynamic methods.
