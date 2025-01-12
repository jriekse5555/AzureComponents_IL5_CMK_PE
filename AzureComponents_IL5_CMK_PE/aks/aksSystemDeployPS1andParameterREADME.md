# Deploy AKS using Powershell script -> az commands -> bicep files using .json parameter file

Based on Bicep CARML modules which are hosted on the following github repo: https://github.com/Azure/ResourceModules

This repo provides fast deployment of the following components with Azure configuration fitting into IL5 compliance requirements by leveraging customer managed keys (CMK) (provisioned in a keyvault) and private endpoints (leveraging associated private dns zones). Security is maximized in this configuration:

- AKS (with Keyvault, Storage Account and ACR)

For a quick reference on IL5 see: https://docs.microsoft.com/en-us/compliance/regulatory/offering-dod-il5

To deploy AKS from the powershell script below it will need to be configured with appropriate variables and reference a json parameter file also with appropriate variables. An Azure DevOps .yml pipeline is in this repo, but not necessary to deploy and only left for Azure DevOps customers. Since the parameter json file is the same regardless of whether the system is launched from powershell or from a .yml file in an ADO pipeline, this more comprehensive guide that includes detail on parameter file parameter may be useful for either approach.

See the primary aks deployment powershell script in this repo for information around prequisites: /src/aks/AzureComponents_IL5_CMK_PE/aks/aksSystemDeploy.ps1

Below are the needed variables for the powershell script and information on the appropriate values:

- $il - Typically three characters that will used for Azure object naming. For example 'PLX'
- $prj - Similar to the one above typically three characters to designate project. For example 'PRJ'
- $deployRgp - Name of the Azure resource group that the Azure objects will be deployed
- $rootPath - The directory path that the repo is located. See the powershell for exact directory level
- $privateLinkSubnetName - The name of the Azure subnet within the Azure virtual network that the objects with private endpoints should be deployed. Can be the same as the subnet for other Azure objects.
- $vnetName - The name of the virtual network Azure objects will be deployed
- $vnetRgp - The name of the virtual network's resource group
- $logAnalyticsResourceId - The log analytic workspace Azure resource id that AKS will be connected
- $kvtAadObjId - The Entra ID (Azure AD) user or group object ID that the deployed keyvault should have set will full permissions
- $kvtPrivateDNSZoneResourceId - The Azure keyvault private dns zone resource id that the keyvault will be registered to for DNS. This is a prerequisite of the script.


An example parameter file is on the path: src/aks/AzureComponents_IL5_CMK_PE/aks/parameters/aksSystemDeploy.example.parameters.json

Below are the needed variables for the parameter file and information on the appropriate values:

- dnsZoneRgpName - The resource group that all the private dns zones exist in. This is necessary including the aks private dns zone.
- dnsZoneRgpSubId - The subscription ID of the DNS Zone resource group above
- cmkDESRoles - This is a list of Disk Encryption sets to create. The default value is fine.
- storageAccountSku - The sku of the storage account. LRS is default as ZRS is not available yet in all environments.
- fileShares - This variable allows additional file shares to be created on the storage account. An empty array is fine.
- aksClusterNetworkPlugin - Default value is fine. Determines AKS network mode.
- aksClusterNetworkPolicy - Default value is fine. Determines AKS network mode.
- aksClusterServiceCidr - Default value is fine. This is for internal routing. Can be left as is even if your private IP scheme is different.
- aksClusterDnsServiceIP - Default value is fine. This is for internal routing. Can be left as is even if your private IP scheme is different.
- aksClusterSkuTier - Determines whether in paid support mode or not. Default is fine.
- aksClusterKubernetesVersion - AKS version. This value changes frequently and will generate an error if does not meet minimum version. May need to be changed to available versions.
- aadProfileAdminGroupObjectIDs - The Entra ID (Azure AD) user or group object ID that will have full admin rights on AKS. Should be configured to ensure this is avialable.
- aksPrivateDNSZoneId - The AKS private DNS zone is a prereq. This is the Azure resource id of the object. It must be in the same resource group as other needed private dns zones. Check your documentation for the exact name. For example, Azure Government is: privatelink.<region>.cx.aks.containerservice.azure.us
- aadProfileManaged - Default is fine. Indicates using AAD groups.
- aadProfileEnableAzureRBAC - Default is fine. Indicates using AAD groups.
- disableLocalAccounts - Default is fine. Adds security by disabling local AKS accounts 
- enablePrivateCluster - Default is fine. A private AKS cluster is what we want to be secure.
- primaryAgentPoolProfile - Defines required system node pool. Subnet resource id is required which is a combiniation of virtual network resource id with the suffix of 'subnets/<name of subnet>'. Subnet resource id is not easily found in the Azure portal
- agentPools - This variable is optional. You will most like want a user node pool for your workloads. Subnet id is required. enableEncryptionAtHost may not be available in the target environment.
- enableKeyvaultSecretsProvider - Default is fine. May be useful to be leveraged in later workload development
- enableSecretRotation - Default is fine. Good security practice.
- enableAzureDefender - Default is fine. This security feature is best set to this value.
- managedOutboundIPCount - Set this to 0 in environments that have an Azure Firewall or other method for egress traffic. The Azure Firewall will need to allow all the URLs to allow access to the Ubuntu images needed to build the node pool hosts. If your AKS deployment is stopping at agent pool deployment check the virtual machine scale set activity logs to see if there are errors around blocked URLs. In test environments this can be set to 1 to allow a pip for egress.
- aksClusterOutboundType - Works in parallel with the variable above managedOutboundIPCount. The default value of UserDefinedRouting indicates use of an Azure Firewall. The other value is LoadBalancer which will create a load balancer with a pip for egress (not for prod).


Copy of CARML modules made for simpicity around 7/1/2022 with slight refinements made for the following modules:

- AKS (to enable Disk Encryption Set linked to CMK, central AKS private DNS zone, and change from outdated API)
- Keyvault\Keys - Added an output to support DES (Latest DES module no longer needs this)