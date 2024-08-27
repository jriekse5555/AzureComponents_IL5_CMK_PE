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

The default AKS CONFIGURATION parameter file in this repo is currently set to use an Outbound IP to retrieve the Ubuntu images from the external repo for the virtual machine scale sets using an Public IP address. When you move to a production environment that sits behind an Azure Firewall or similar perimeter guard the following two values in the parameter file are needed to avoid using a Public IP (PIP). Note the Azure Firewall (perimeter outbound) needs to allow the outbound connection to the external repo location with this configuration. Here are the parameters and values for the parameter file:

managedOutboundIPCount - 0
aksClusterOutboundType - userDefinedRouting

Note Azure Dedicated Hosts are not supported with AKS so IL5 compliance would require using VM sku sizes that take the entire host (or seeking an exception)

The simplest way to test the system is to do the following:

- Download this github repo as a .zip
- Request a free Azure DevOps Services organization at https://dev.azure.com
- Create a new Azure DevOps Services (ADO) project
- Initialize the repo in the project
- Clone the repo locally using the ADO GUI and Visual Studio Code
- Add the contents of the .zip downloaded earlier into the clone using Windows explorer, and use Visual Studio Code's git interface to create a commit and push the code to ADO
- Request an Azure subscription from https://portal.azure.com or use one you already have
- Create an Azure quota to ensure you don't spend too much
- Create an Azure resource group, virtual network, subnet, and nsg (you may want to use a region that isn't heavily used)
- Create an Azure virtual machine (preferrably using a spot instance to save on cost)
- Create a rule in the Azure nsg allowing only the public IP that you are using via RDP to ensure your Azure VM is protected (a website like https://whatismyipaddress.com/ can show you the public ip you are using)
- Create an Azure service principal (in Entra ID app registrations) and grant it access as Contributor (AKS will need Owner on the subscription as it creates a resource group) to your resource group or subscription
- Back in ADO, create a service connection with the previous service principal's information
- Edit one of the ADO .yml pipelines (in the repo) with your Azure information
- Create an Azure pipeline with ADO, from the .yml file in the repo
- Navigate to ADO agent pools, and follow the instructions to get ready to install an agent on your Azure VM. You'll need a ADO PAT with Agent Pools (Manage and Read)
- Go back to your Azure VM, and follow the instructions to register the agent pool
- Install Powershell 7 and Azure CLI on the VM and restart the agent pool (which should be registered in ADO)
- Create other required Azure objects (Log Analytics, and the necessary private dns zones linked with your vnet)
- Run your pipeline from ADO and verify success
- You may want to delete deployed objects as they can add up in cost

Note that the Azure DevOps Server Pipelines that are published rely on the AZ Cli ADO task. This task calls az commands using a cmd /c command and passes the required parameters including the service principal password. If you are using Windows self-hosted build agents and the Windows advanced auditing setting 'Audit Process Creation' this will capture the process creation command line and save the service principal password in the audit logs. Consider certificate based service principal authentication or avoiding this audit setting for Windows build agents. 
