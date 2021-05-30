Write-output "Initializing Azure services..." "`n" 

. /workspace/SimpleDotnetMysql/kubescript/deployKube/aks-keyvault_withoutdotgit/initParameters.ps1

$isPrompt = 'false'

$isManual='false'
$step=$step+1
$description = "Create Azure MySQL Service."
$command="az mysql server create -l southeastasia -g $resourceGroupName -n 'mysqlxx$suffix' -u $mysqlAdmin -p $dbPassword --sku-name B_Gen5_1 --version 5.7 --output table"
excec-Command $command $step $isManual $isPrompt $description

$subnetId = az network vnet subnet list --resource-group $resourceGroupName --vnet-name $vnetName --query "[?contains (name,'$clusterSubnetName')].id" --output tsv
$subnetId = [string]::join("",($subnetId.Split("`n")))   # To remove newline

$isManual='false'
$step=$step+1
$description = "Create Azure Container Registry (ACR)."
$command="az acr create --resource-group $resourceGroupName --name $acrName --sku Basic --output table"
$acr= excec-Command-ReturnV $command $step $isManual $isPrompt $description
$acr = [string]::join("",($acr.Split("`n")))   # To remove newline

$isManual='false'
$step=$step+1
$description = "Create Azure kubernetes Service (AKS)."
$command="az aks create -n $aksName -g $resourceGroupName --kubernetes-version $aksVersion --node-count 1 --attach-acr $acrName --enable-managed-identity --network-plugin azure --vnet-subnet-id $subnetId --docker-bridge-address $dockerBridgeAddress --dns-service-ip $dnsServiceIP --service-cidr $serviceCIDR --max-pods 60 --node-vm-size Standard_DS2_v2| ConvertFrom-Json"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$command="az aks enable-addons -a monitoring -n $aksName -g $resourceGroupName"
excec-Command $command $step $isManual $isPrompt

$localmachinesubnetId = az network vnet subnet list --resource-group $resourceGroupName --vnet-name $vnetName --query "[?name=='$localMachineSubnet'].id" | ConvertFrom-Json

#$isManual='false'
#$step=$step+1
#$description = "Create Azure DMS Service. This is for online database migration."
#$command="az dms create -l southeastasia -n dms-$suffix -g $resourceGroupName --sku-name Premium_4vCores --subnet $localmachinesubnetId"
#excec-Command $command $step $isManual $isPrompt $description

write-output "DMS must be provisioned manually by Azure Portal. 
              1. Resoucegroup: rg-{suffix}
              2. name: dms-{suffix}
              3. sku: Premium_4vCores
              4. subnet: localmachinesubnet"