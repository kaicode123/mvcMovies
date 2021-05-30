Write-output "Welcome to LAB: Section#01 Simulate the local environment" "`n"


$rootDir = "/workspace/aspnetcore-mysql-docker";
$rootDir = Read-Host -Prompt "Set root working directory [$rootDir]"
if ([string]::IsNullOrWhiteSpace($rootDir)){
  $rootDir = "/workspace/aspnetcore-mysql-docker"
}

$suffix  = Read-Host -Prompt "Please enter your assigned suffix ID"

Write-output ">>>############# #Step 1. Initiate mysql docker container on local computer ..." "`n"

Write-output " Stop all running docker containers."
Write-output "Executing: docker stop $(docker ps -a -q) " "`n"
docker stop $(docker ps -a -q)
Write-output "Done. " "`n"

Write-output " Delete all running docker containers."
Write-output "Executing: docker rm $(docker ps -a -q) " "`n"
docker rm $(docker ps -a -q)
Write-output "Done. " "`n"



Write-output "#Step 1.1 - Pull mysql image from docker hub. "
Write-output "Executing: docker pull mysql " "`n"
docker pull mysql
Write-output "Done. " "`n"

Write-output "#Step 1.2 - Setup mysql name "
$mysqlName = "mysql" + $suffix 
Write-output "Your mysql name is $mysqlName  " "`n"

Write-output "#Step 1.3 - start mysql docker container on local computer. "
Write-output "Executing: docker run -p 33060:3306 --name $mysqlName -e MYSQL_ROOT_PASSWORD=my_password -e MYSQL_DATABASE=people -d mysql " "`n"
#docker run -p 33060:3306 --name $mysqlName -e MYSQL_ROOT_PASSWORD=my_password -e MYSQL_DATABASE=people -d mysql/mysql-server 
docker run -p 33060:3306 --name $mysqlName -e MYSQL_ROOT_PASSWORD=my_password -e MYSQL_DATABASE=people -d mysql/mysql-server
Write-output "Done. " "`n"

Write-output "#Step 1.4 - Verify mysql container status. "
Write-output "Executing: docker ps" "`n"
docker ps
Write-output "Done. " "`n"

Write-output "#Step 1.5 - get container ID. "
Write-output "Executing: docker ps -aqf name=$mysqlName " "`n"
sleep 10
$mysqlContainerID = docker ps -aqf name=$mysqlName
Write-output "Done. " "`n"

Write-output "#Step 1.6 - [Manual steps] Grant root previledges to access mysql from any host. " "`n"
Write-output "Once bash prompt shows (#), type 'exit' "  "`n"
Write-output "Once mysql-client prompt shows (mysql), please enter the follow sql query commands: "  "`n"
Write-output "CREATE USER 'root'@'%' IDENTIFIED BY 'my_password'; and hit enter"
Write-output "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; and hit enter"
Write-output "flush privileges; and hit enter" "`n"
Write-output "Once done, type 'exit'" "`n"

Write-output "Executing: docker exec -it $mysqlContainerID mysql -uroot -pmy_password " "`n"

bash
docker exec -it $mysqlContainerID mysql -uroot -pmy_password
Write-output "Done. " "`n"

Write-output "#Step 1.7 - [Manual steps] Import database to mysql " "`n"
Write-output "Once bash prompt shows (#), type the following query commands  " 

Write-output "mysql -uroot -pmy_password --port=33060 --protocol=TCP < ../../../mysqlimport/modified/schema.sql  and hit enter"
Write-output "mysql -uroot -pmy_password --port=33060 --protocol=TCP < ../../../mysqlimport/modified/film-data.sql and hit enter" "`n"
Write-output "Once done, type exit" 
bash


Write-output ">>>############# #Step 2. Build and run mySimpleApp on local computer ..." "`n"

Write-output "#Step 2.1 - Change working directory to mySimpleApp and clean previous build (if any) "
Write-output "Executing: Set-Location $rootDir"/CoreWebAppSimple/""
$rootDir2 = $rootDir + "/CoreWebAppSimple/"

Set-Location  $rootDir"/CoreWebAppSimple/" 

Write-output "Executing: dotnet clean"
dotnet clean
Write-output "done. " "`n"

Write-output "#Step 2.2 - Build mySimpleApp "
Write-output "Executing: dotnet build"
dotnet build
Write-output "done. " "`n"

Write-output "#Step 2.3 - Run mySimpleApp "
Write-output "Executing: dotnet run" "`n"
Write-output "Once done, copy web URL and put in web browser for testing."
Write-output "Review the result by accessing MySQLData link and type 'ctrl+c'." "`n"

dotnet run
Write-output "done. " "`n"

Set-Location  $rootDir"/kubescript/deployKube/aks-keyvault_withoutdotgit"



<#
Write-output "Retriving Subscription ID ..."

build -t mysimpleapp ../../.

#Write-output "Start preparing all environment variables ... " "`n"

$suffix  = Read-Host -Prompt "Please enter your assigned suffix ID"

Write-output "Retriving Subscription ID ..."
$subscriptionId = (az account show | ConvertFrom-Json).id
Write-output "Your subsription ID is: $subscriptionId " "`n"

Write-output "Retriving Tenant ID ..."
$tenantId = (az account show | ConvertFrom-Json).tenantId
Write-output "Your Tenant ID is: $tenantId " "`n"

$location = "southeastasia";
$location = Read-Host -Prompt "Please enter Azure Region [$location]"
if ([string]::IsNullOrWhiteSpace($location)){
  $location = "southeastasia"
}
Write-output "Your Azure Region is: $location " "`n"

Write-output ">>>############# Creating Resoucre Group ..."

Write-output "setting up Resource Group Name ..."
$resourceGroupName = "rg-" + $suffix
Write-output "Your Resource Group Name is: $resourceGroupName " "`n"

$resourceGroup = az group create -n $resourceGroupName -l $location | ConvertFrom-Json

Write-output "<<<############# Resoucre Group Created." "`n"

Write-output ">>>############# Creating vNET and subnet for aks cluster and pods ..."
Write-output "setting up vNET name ..."
$vnetName = "vnet-" + $suffix
Write-output "Your vNET name is: $vnetName " "`n"

Write-output "setting up vNET address prefix ..."
$vnetAddressPrefix = "10.10.0.0/16"
Write-output "Your vNET address prefix is: $vnetAddressPrefix " "`n"

Write-output "setting up aks cluster subnet name ..."
$clusterSubnetName = "clusterSubnet-" + $suffix
Write-output "Your aks cluster subnet name is: $clusterSubnetName  " "`n"

Write-output "setting up aks cluster subnet address [used by both aks and all pods] ..."
$clusterSubnetAddress = "10.10.10.0/24"
Write-output "Your aks cluster subnet address is: $clusterSubnetAddress  " "`n"

Write-output "creating vNet and subnet..."
az network vnet create -g $resourceGroupName -n  $vnetName --address-prefix $vnetAddressPrefix --subnet-name $clusterSubnetName --subnet-prefix $clusterSubnetAddress
Write-output "done." "`n"

Write-output "<<<############# vNET and subnet for aks cluster and pods created." "`n"

Write-output "############# Creating ACR ..." "`n"
Write-output "setting up ACR name ..."
$acrName = "acrforaks" + $suffix
Write-output "ACR name is $acrName" "`n"

Write-output "Creating ACR service ..."
$acr = az acr create --resource-group $resourceGroupName --name $acrName --sku Basic | ConvertFrom-Json
az acr login -n $acrName --expose-token
Write-output "done." "`n"

Write-output "############# ACR Created." "`n"


Write-output ">>>############# Creating aks ..."
Write-output "setting up aks name ..."
$aksName = "aks-" + $suffix
Write-output "Your aks name is: $aksName  " "`n"

Write-output "setting up aks version ..."
$aksVersion = "1.18.6"
Write-output "Your aks version is: $aksVersion  " "`n"

Write-output "setting up aks Docker Bridge Address ..."
$dockerBridgeAddress = "172.17.0.1/16"
Write-output "Your aks Docker Bridge Address is: $dockerBridgeAddress  " "`n"

Write-output "setting up aks DNS Service IP ..."
$dnsServiceIP = "10.2.0.10"
Write-output "Your aks DNS Service IP is: $dnsServiceIP  " "`n"

Write-output "setting up aks Service CIDR ..."
$serviceCIDR = "10.2.0.0/24"
Write-output "Your aks DNS Service IP is: $serviceCIDR  " "`n"

Write-output "Registering aks service to the subscription ..."
az provider register --namespace Microsoft.ContainerInstance
Write-output "done." "`n"

Write-output "Retrieving subnet ID for deploying aks cluster ..."
$subnetId = az network vnet subnet list --resource-group $resourceGroupName --vnet-name $vnetName --query "[0].id" --output tsv
Write-output "done." "`n"

Write-output "Creating aks service ..."
$aks = az aks create -n $aksName -g $resourceGroupName --kubernetes-version $aksVersion --node-count 1 --attach-acr $acrName --enable-managed-identity --network-plugin azure --vnet-subnet-id $subnetId --docker-bridge-address $dockerBridgeAddress --dns-service-ip $dnsServiceIP --service-cidr $serviceCIDR | ConvertFrom-Json
$aks = (az aks show -n $aksName -g $resourceGroupName | ConvertFrom-Json)
Write-output "done." "`n"

Write-output "<<<#############  aks created ..." "`n"

Write-output ">>>############# Enabling aks virtual node add-on ..." "`n"

Write-output "setting up aks Virtual Node Subnet name ..."
$virtualNodeSubnetName = "virtualNodeSubnet-" + $suffix
Write-output "Your aks Virtual Node Subnet name is: $virtualNodeSubnetName  " "`n"

Write-output "setting up aks Virtual Node Subnet address [used by containners that are scheduled on Azure ACI] ..."
$virtualNodeSubnetAddress = "10.10.11.0/24"
Write-output "Your aks Virtual Node Subnet address is: $virtualNodeSubnetAddress  " "`n"

Write-output "creating aks Virtual Node Subnet ..."
az network vnet subnet create --resource-group $resourceGroupName --vnet-name $vnetName --name $virtualNodeSubnetName --address-prefixes $virtualNodeSubnetAddress
Write-output "done." "`n"

Write-output "Enabling aks Virtual Node add-on ..."
az aks enable-addons --resource-group $resourceGroupName  --name $aksName --addons virtual-node --subnet-name $virtualNodeSubnetName
Write-output "done." "`n"

Write-output "Retrieving Managed Identity for aks to access ACI (virtual node)"
$identity2 = az identity list -g $aks.nodeResourceGroup --query "[?contains(name, 'aciconnectorlinux')]"  | ConvertFrom-Json
Write-output "done." "`n"

### to be improved to scope more to only vNET "NOT" entire resource group.
Write-output "Assigning Contributor Role to the Managed Identity for Resource Group that contain vNET of Virtual Node..."
az role assignment create --role "Contributor" --assignee $identity2.principalId --scope /subscriptions/$subscriptionId/resourcegroups/$($resourceGroupName)
Write-output "done." "`n"

Write-output "<<<############# aks virtual node add-on enabled." "`n"

Write-output ">>>############# Authenticating kubectl to connect to aks ..."

az aks get-credentials -n $aksName -g $resourceGroupName --overwrite-existing

Write-output "<<<############# kubectl to connect to aks authenticated ..." "`n"



Write-output ">>>############# Create key vault ..."

Write-output "setting up Key Vault name ..."
$keyVaultName = "keyvaultaks" + $suffix
Write-output "Key Vault name is $keyVaultName" "`n"

Write-output "setting up Key Vault Secret1 name ..."
$secret1Name = "DatabaseLogin"
Write-output "Key Vault Secret1 name is $secret1Name" "`n"

Write-output "setting up Key Vault Secret1 Alias ..."
$secret1Alias = "DATABASE_LOGIN"
Write-output "Key Vault Secret1 Alias is $secret1Alias" "`n"

Write-output "setting up Key Vault Secret1  ..."
$secret1 = "Houssem"
Write-output "Key Vault Secret1  is $secret1" "`n"

Write-output "setting up Key Vault Secret2 name ..."
$secret2Name = "DatabasePassword"
Write-output "Key Vault Secret2 name is $secret2Name" "`n"

Write-output "setting up Key Vault Secret2 Alias ..."
$secret2Alias = "DATABASE_PASSWORD" 
Write-output "Key Vault Secret2 Alias is $secret2Alias" "`n"

Write-output "setting up Key Vault Secret2  ..."
$secret2 = "P@ssword123456"
Write-output "Key Vault Secret1  is $secret2" "`n"


Write-output "creating key vault service ..."
$keyVault = az keyvault create -n $keyVaultName -g $resourceGroupName -l $location --enable-soft-delete true --retention-days 7 | ConvertFrom-Json
Write-output "done." "`n"

Write-output "setting secret1 and secret2 ..."
az keyvault secret set --name $secret1Name --value $secret1 --vault-name $keyVaultName
az keyvault secret set --name $secret2Name --value $secret2 --vault-name $keyVaultName
Write-output "done." "`n"

Write-output "<<<############# key vault created." "`n"

Write-output ">>>############# Installing Secrets Store CSI Driver using Helm ..." "`n"

Write-output "Creating namespace for csi-driver..." "`n"
kubectl create ns csi-driver
Write-output "done." "`n"

Write-output "Installing Secrets Store CSI Driver with Azure Key Vault Provider..."
helm repo add csi-secrets-store-provider-azure https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/charts
helm install csi-azure csi-secrets-store-provider-azure/csi-secrets-store-provider-azure --namespace csi-driver
sleep 2
Write-output "done." "`n"

Write-output "Verifying csi-driver pods" "`n"
kubectl get pods -n csi-driver

Write-output "<<<############# Secrets Store CSI Driver using Helm created." "`n"

Write-output ">>>############# Creating Azure Key Vault Provider..." "`n"

Write-output "setting up Secret Provider Class name ..."
$secretProviderClassName = "secret-provider-kv"
Write-output "Secret Provider Class name is $secretProviderClassName" "`n"

Write-output "Preparing yaml STDIN for Azure Key Vault Provider ..." "`n"
$secretProviderKV = @"
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: $($secretProviderClassName)
spec:
  provider: azure
  parameters:
    usePodIdentity: "true"
    useVMManagedIdentity: "false"
    userAssignedIdentityID: ""
    keyvaultName: $keyVaultName
    cloudName: AzurePublicCloud
    objects:  |
      array:
        - | 
          objectName: $secret1Name 
          objectAlias: $secret1Alias
          objectType: secret
          objectVersion: ""
        - |
          objectName: $secret2Name
          objectAlias: $secret2Alias
          objectType: secret
          objectVersion: ""
    resourceGroup: $resourceGroupName
    subscriptionId: $subscriptionId
    tenantId: $tenantId
"@
Write-output "done." "`n"

Write-output "Creating Azure Key Vault Provider from yaml STDIN ..." 
$secretProviderKV | kubectl create -f -
Write-output "done." "`n"

Write-output "<<<############# Azure Key Vault Provider created." "`n"

Write-output ">>>############# Installing aad Pod identity into aks using helm..." "`n"

az role assignment create --role "Managed Identity Operator" --assignee $aks.identityProfile.kubeletidentity.clientId --scope /subscriptions/$subscriptionId/resourcegroups/$($aks.nodeResourceGroup)
az role assignment create --role "Virtual Machine Contributor" --assignee $aks.identityProfile.kubeletidentity.clientId --scope /subscriptions/$subscriptionId/resourcegroups/$($aks.nodeResourceGroup)

helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts
helm install pod-identity aad-pod-identity/aad-pod-identity

Write-output "Verifying aad Pod identity pods ..."
kubectl get pods

Write-output "Retrieving agentpool identity ..."

$identity=$null
while($identity -eq $null) {
echo "Retrying until Identity is ready..."
$identity = az identity list -g $aks.nodeResourceGroup --query "[?contains(name, 'agentpool')]"  | ConvertFrom-Json                                        
}
Write-output "done." "`n"

Write-output "Assigning Reader Role to agentpool Identity for Key Vault..."
az role assignment create --role "Reader" --assignee $identity.principalId --scope $keyVault.id
Write-output "done." "`n"

Write-output "Setting ""get"" policy to access secrets in Key Vault for agentpool identity..."
az keyvault set-policy -n $keyVaultName --secret-permissions get --spn $identity.clientId
Write-output "done." "`n"

Write-output "<<<############ aad Pod identity into aks using helm installed."

Write-output ">>>############# Adding AzureIdentity and AzureIdentityBinding..."

Write-output "setting up identity name ..."
$identityName = "identity-aks-kv" 
Write-output "identity name is $identityName" "`n"

Write-output "setting up identity selector ..."
$identitySelector = "azure-kv" 
Write-output "identity selector is $identitySelector" "`n"

Write-output "Preparing yaml STDIN for aad pod identity and binding ..."

$aadPodIdentityAndBinding = @"
apiVersion: aadpodidentity.k8s.io/v1
kind: AzureIdentity
metadata:
  name: $($identityName)
spec:
  type: 0
  resourceID: $($identity.id)
  clientID: $($identity.clientId)
---
apiVersion: aadpodidentity.k8s.io/v1
kind: AzureIdentityBinding
metadata:
  name: $($identityName)-binding
spec:
  azureIdentity: $($identityName)
  selector: $($identitySelector)
"@
Write-output "done." "`n"

Write-output "Creating aad pod identity and binding from yaml STDIN ..."
$aadPodIdentityAndBinding | kubectl apply -f -
Write-output "done." "`n"

Write-output "<<<############# AzureIdentity and AzureIdentityBinding added." "`n"


Write-output ">>>############# Deploying a Nginx Pod to test the access to key vault to retrieve the secrets ..."

Write-output "Preparing yaml STDIN for nginx pod ..."
$nginxPod = @"
kind: Pod
apiVersion: v1
metadata:
  name: nginx-secrets-store
  labels:
    aadpodidbinding: $($identitySelector)
spec:
  containers:
    - name: nginx
      image: nginx
      volumeMounts:
      - name: secrets-store-inline
        mountPath: "/mnt/secrets-store"
        readOnly: true
  volumes:
    - name: secrets-store-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
         secretProviderClass: $($secretProviderClassName)
"@
Write-output "done." "`n"

Write-output "Creating nginx pod from yaml STDIN ..."
$nginxPod | kubectl apply -f -
Write-output "done." "`n"

Write-output "Verifying nginx pod ..."
sleep 20
kubectl get pods

Write-output "Validating nginx pod has access to the secrets from Key Vault..."
kubectl exec -it nginx-secrets-store -- ls /mnt/secrets-store/
"`n"
kubectl exec -it nginx-secrets-store -- cat /mnt/secrets-store/DATABASE_LOGIN
"`n"
kubectl exec -it nginx-secrets-store -- cat /mnt/secrets-store/$secret1Alias
"`n"
kubectl exec -it nginx-secrets-store -- cat /mnt/secrets-store/DATABASE_PASSWORD
"`n"
kubectl exec -it nginx-secrets-store -- cat /mnt/secrets-store/$secret2Alias
"`n"
Write-output "done." "`n"

Write-output "<<< ############# a Nginx Pod to test the access to key vault to retrieve the secrets deployed." "`n"
#echo "test acr AUTHEN with aks"
# az acr build -t productsstore:0.1 -r $acrName .\ProductsStoreOnKubernetes\MvcApp\
# kubectl run --image=$acrName.azurecr.io/productsstore:0.1 prodstore --generator=run-pod/v1

echo "Deleting all resources. No wait mode."
az group delete --no-wait --yes -n $resourceGroupName
az group delete --no-wait --yes -n $aks.nodeResourceGroup
#>







