Write-output "initializing the Parameters.. " "`n" 

# Section Setup suffix ---------------------------------
#$suffix  = Read-Host -Prompt "Please enter your assigned suffix ID"
$suffix = '001'  # [these must be 001 to 016]

# Section Setup email ---------------------------------
#$emailWorkshop  = Read-Host -Prompt "Please enter your workshop email"
$emailWorkshop = "happylab001@outlook.com"

# subscription Setup ------------------------------------
#$subscriptionName ="Microsoft Azure Sponsorship"
$subscriptionName ="AzurePass-001"
#-- Section Setup Parameters -----------------------------------------------------------
$rootDir = "/workspace/SimpleDotnetMysql";
$workspace = "/workspace"
$mvcmovieDir = $rootDir + "/MvcMovie"
$SectionRoot = $rootDir + "/kubescript/deployKube/aks-keyvault_withoutdotgit"
$scriptRoot = $rootDir + "/kubescript/deployKube"
$microServiceDir = $rootDir + "/MvcMovieMicroService"
$tempDir = "/workspace/SimpleDotnetMysql/kubescript/deployKube/temp"
$dbPassword ="1Q2w3e4r5t6y"
$resourceGroupName = "rg-" + $suffix
$vnetName = "vnet-" + $suffix
$localMachineSubnet ="localmachinesubnet"
$mysqlAdmin = "mysqladmin" + $suffix
$acrName = "acrforaks" + $suffix
$websitePrefix = "moviescc"
$websiteName = "$websitePrefix$suffix"
#----------------------------------------------
$aksName = "aks-" + $suffix
$aksVersion = "1.18.10"
$dockerBridgeAddress = "172.17.0.1/16"
$dnsServiceIP = "10.2.0.10"
$serviceCIDR = "10.2.0.0/24"
$location = "southeastasia";
$vnetName = "vnet-" + $suffix
$vnetAddressPrefix = "10.10.0.0/16"
#$clusterSubnetName = "clusterSubnet-" + $suffix
$clusterSubnetName = "clusterSubnet"
$clusterSubnetAddress = "10.10.10.0/24"
$localMachineName = "localmachine"
$mysqlName = "mysql" + $suffix 
$step=0
$env:PATH += ":/root/.dotnet/tools/"
$frontendServiceName = "lbmvcmoviefrontend" + $suffix 
$domainName = "happylab001.ml"
$frontFQDN = "$websiteName.$domainName"
$isPrompt = 'true'
$appPassword = "BJ~__2o-BzI06fXutaxiZ3HnQLAol-YwV-"
$managedDiskName = "localMachineVMDisk"
#$domainName = "happylab$suffix.ml"

# --- DevOps
#$increment ="1"
#$OrgSuffixName = "devopsorg$suffix" + $increment
#$OrgSuffixName = "devopsorgb1"
# ---------------------------------------------------
$kubeDockerFileDir = @('moviesAPI_get','moviesAPI_detail', 'moviesAPI_create', 'moviesAPI_edit', 'moviesAPI_delete', 'MvcMovie')
$kubePort = @('7771', '7772', '7773', '7774', '7775', '80')
$kubeName= @('apiget', 'apidetail', 'apicreate', 'apiedit', 'apidelete', 'mvcmoviefrontend')

#-- Key vault
$keyVaultName = "keyvaultaks" + $suffix
$secret2Name = "connectionString"
$secret2Alias = "connectionString" 
$secret2 = "Server=mysqlxx$suffix.mysql.database.azure.com; Port=3306; Database=movies; Uid=mysqladmin$suffix@mysqlxx$suffix; Pwd=1Q2w3e4r5t6y; SslMode=Preferred;"
$secretProviderClassName = "secret-provider-kv"
$identityName = "identity-aks-kv" 
$identitySelector = "azure-kv" 
$identityName2 = "SimpleID3"
# Section import modules -----------------------------
Remove-Module -Name "modules"
Import-Module -Name "$SectionRoot\modules.psm1"

# Section install hey
snap install hey

# Section Setup Azure account and subscription ------
$isManual='false'
$step=$step+1
#$command="az login -u $emailWorkshop" 
$command="az login" 

excec-Command $command $step $isManual


# TO DO -- change hardcode of subsription name to $subscriptionName
$isManual='false'
$step=$step+1
$command="az account set --subscription '$subscriptionName'" 
excec-Command $command $step $isManual
az extension add --name dms-preview

# Variables that are assigned only after az login.
$localMachineIP = az vm show -d -g $resourceGroupName -n $localMachineName --query publicIps -o tsv
$subscriptionId = (az account show | ConvertFrom-Json).id
$tenantId = (az account show | ConvertFrom-Json).tenantId