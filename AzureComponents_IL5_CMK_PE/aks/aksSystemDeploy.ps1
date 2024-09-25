#Summary - Use Azure CLI, and bicep to deploy an AKS system with a private cluster, using CMKs, and Private Endpoints for Keyvault, ACR, and Storage Account File Shares/Blobs.

#Environment Pre-reqs:
#- Run with user or service principal with Owner permissions on the subscription. AKS creates a resource group for its Virtual Machine Scale Sets and sets permissions on it requiring Owner subscription permissions to do this.
#- Have Azure CLI, bicep, and Powershell installed and configured on your system
#- Log onto Azure with Azure CLI
#- Windows OS. Deployment not tested on linux, but could be easily adapted.


#Azure Pre-reqs:
#- Virtual networks
#- Resource Groups
#- Private DNS Zones for Storage Account File Shares/Blob, Keyvault, ACR, and AKS

#What is Deployed:
#- (Task 1) Keyvault with Private Endpoints, using CMKs
#    Why? - Re-deploying keyvaults wipes out access policies which is problematic for one-time DES permissions
#- (Task 2) Leveraging a separate complex parameter file for additional parameters
#  - User Managed Identities
#  - Array of Customer Managed Keys
#  - Associated Disk Encryption Sets
#  - Keyvault with Private Endpoints, using CMKs
#  - Storage Account with Private Endpoints, using CMKs, and File Shares
#  - Acr with Private Endpoint, using CMK
#  - Aks Private Cluster using Disk Encryption Set with Configurable Node Pools

#Configure the following parameters along with the AKS parameter file

#Deployment IL ie. IL5 - enter impact level for naming
$il='il5'
#Project name used as a prefix for naming objects
$prj='jr9'
#Azure deployment Resource Group where objects will be deployed
$deployRgp='BuildingBlocks'
#Path of the root of the repository
$rootPath='C:\Users\jiriekse\Documents\git\AzureComponents_IL5_CMK_PE'
#Existing Private Endpoint Subnet Name
$privateLinkSubnetName='Subnet1'
#Existing Vnet Name
$vnetName='BuildingBlocks'
#Existing Vnet Resource Group
$vnetRgp='BuildingBlocks'
#Existing Log Analytics Resource Id
$logAnalyticsResourceId='/subscriptions/2658555b-efbe-4958-9088-475d8083bc0e/resourceGroups/BuildingBlocks/providers/Microsoft.OperationalInsights/workspaces/defaultlaworkspacejiriekse'
#Azure AD Group Object ID for Keyvault Access
$kvtAadObjId='011101e7-60e7-4c4d-a4e0-03eacaaf9960'
#Existing Keyvault Private DNS Zone
$kvtPrivateDNSZoneResourceId='/subscriptions/2658555b-efbe-4958-9088-475d8083bc0e/resourceGroups/buildingblocks/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net'

$kvtName=$prj+$il+"kvt"
az keyvault show -n $kvtName -g $deployRgp
if (0 -ne $LASTEXITCODE) {
  $deploymentName = "keyvault-deploy-$((get-date).ToString('MMddyyyy-hhmmss'))"
  az deployment group create -n $deploymentName -g $deployRgp `
    --template-file "$rootPath\keyvault\kvtDeployCarml.bicep" `
    --parameters kvtName=$kvtName `
                  kvtRgpName=$deployRgp `
                  privateLinkSubnetName=$privateLinkSubnetName `
                  vnetName=$vnetName `
                  vnetRgp=$vnetRgp `
                  logAnalyticsResourceId=$logAnalyticsResourceId `
                  kvtAadObjId=$kvtAadObjId `
                  kvtPrivateDNSZoneResourceId=$kvtPrivateDNSZoneResourceId
}

$deploymentName = "aks-deploy-$((get-date).ToString('MMddyyyy-hhmmss'))"

az deployment group create -n $deploymentName -g $deployRgp `
  --template-file "$rootPath/aks/aksSystemDeploy.bicep" `
  --parameters "@$rootPath/aks/parameters/aksSystemDeploy.jr9.parameters.json" `
                prj=$prj `
                il=$il `
                vnetName=$vnetName `
                vnetRgp=$vnetRgp `
                privateLinkSubnetName=$privateLinkSubnetName `
                kvtName=$kvtName `
                priRgpName=$deployRgp `
                logAnalyticsResourceId=$logAnalyticsResourceId

