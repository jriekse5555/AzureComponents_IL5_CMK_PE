# AzureComponents_IL5_CMK_PE

Based on Bicep CARML modules which are hosted on the following github repo: https://github.com/Azure/ResourceModules

This repo provides fast deployment of the following components with Azure configuration fitting into IL5 compliance requirements by leveraging customer managed keys (CMK) (provisioned in a keyvault) and private endpoints (leveraging associated private dns zones):

- Keyvault
- Storage Account
- Azure Container Registry (ACR)
- AKS (with Keyvault, Storage Account and ACR)

For a quick reference on IL5 see: https://docs.microsoft.com/en-us/compliance/regulatory/offering-dod-il5

Prequisites for use are:
- Existing virtual network
- Existing subnet with private endpoint policies disabled to allow addition of private endpoints
- Existing Private DNS Zone for objects deployed (AKS, Storage (File/Blob), Keyvault, ACR) AND linked to the virtual network planned for DNS resolution.
- (For AKS) Existing subnet large enough to hold AKS node pools (30 IPs per node pool is the set default)
- (For Storage and ACR) Keyvault is deployed first (to hold the CMK)

To deploy, Azure DevOps (Server OR Services) .yml pipelines and associated .bicep files containing all the security components are within this repo. Azure DevOps can pull the github repo directly or you can copy to a DevOps repo. If you don't have Azure DevOps available, you can leverage the Azure CLI commands within them directly. 

Copy of CARML modules made for simpicity around 7/1/2022 with slight refinements made for the following modules:

- AKS (to enable Disk Encryption Set linked to CMK AND central AKS private DNS zone)
- Keyvault\Keys - Added an output to support DES (Latest DES module no longer needs this)

Numerous improvements are made to the central CARML repo on a recurring basis so its recommended that you evaluate the latest module versions as needed. The copy is leveraged to ensure changes don't break existing code. There are also several CARML versioning methods that can be used instead if all your environments support this and you are interested in more dynamic methods.

Note Azure Dedicated Hosts are not supported with AKS so IL5 compliance would require using VM sku sizes that take the entire host (or seeking an exception)

Note that the Azure DevOps Server Pipelines that are published rely on the AZ Cli ADO task. This task calls az commands using a cmd /c command and passes the required parameters including the service principal password. If you are using Windows self-hosted build agents and the Windows advanced auditing setting 'Audit Process Creation' this will capture the process creation command line and save the service principal password in the audit logs. Consider certificate based service principal authentication or avoiding this audit setting for Windows build agents. 
