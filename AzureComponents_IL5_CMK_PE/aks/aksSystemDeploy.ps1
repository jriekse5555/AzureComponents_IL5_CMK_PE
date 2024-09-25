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
#- Resource Providers enabled for necessary components

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

#Deployment IL ie. IL5 - enter impact level or environment name for naming
$il='<environment short name>'
#Project name used as a prefix for naming objects
$prj='<project short name>'
#Azure deployment Resource Group where objects will be deployed
$deployRgp='<rg>'
#Path of the root of the repository
$rootPath='<path to source directory>\AzureComponents_IL5_CMK_PE\AzureComponents_IL5_CMK_PE'
#Existing Private Endpoint Subnet Name
$privateLinkSubnetName='<subnet name>'
#Existing Vnet Name
$vnetName='<vnet name>'
#Existing Vnet Resource Group
$vnetRgp='<vnet rg>'
#Existing Log Analytics Resource Id
$logAnalyticsResourceId='<resource id>'
#Azure AD Group Object ID for Keyvault Access
$kvtAadObjId='<object id>'
#Existing Keyvault Private DNS Zone
$kvtPrivateDNSZoneResourceId='<resource id>'

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
  --parameters "@$rootPath/aks/parameters/aksSystemDeploy.example.parameters.json" `
                prj=$prj `
                il=$il `
                vnetName=$vnetName `
                vnetRgp=$vnetRgp `
                privateLinkSubnetName=$privateLinkSubnetName `
                kvtName=$kvtName `
                priRgpName=$deployRgp `
                logAnalyticsResourceId=$logAnalyticsResourceId

#Disable app ingress gateway for environments that don't support it which will prevent upgrading aks (without this)
#az aks disable-addons -n "$prj-$il-aks" -g $deployRgp -a ingress-appgw

#If interested in attaching the ACR to AKS for pulling images the following commands are needed:
#$acrName = $prj+$il+"acr"
#az aks update -n "$prj-$il-aks" -g $deployRgp --attach-acr $acrName

