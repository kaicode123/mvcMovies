Write-output "Welcome to LAB Section#1 Application migration to Azure AKS" "`n" 

. /workspace/SimpleDotnetMysql/kubescript/deployKube/aks-keyvault_withoutdotgit/initParameters.ps1


$dmsProjectNameAvailableStatus = az dms project check-name --service-name dms-$suffix --name dmsproject-$suffix -g rg-$suffix --query ["nameAvailable"] -o tsv

#if($dmsProjectNameAvailableStatus -eq 'false'){

 #   write-Host "The previous dms project still exists. Please manually remove by Azure Portal and exectue section01.ps1 again."
 #  exit
#}


$isPrompt = 'true'


#$isManual='true'
#$step=$step+1
#$description = "Please change your DNS Server to 8.8.8.8 to ensure that dns record cache works properly."
#$command="Go to your netowrk adaptor setting and change DNS Server to 8.8.8.8"
#excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Initial some data in MySQL DB. This will be migrated to Azure MySQL Service (PaaS)."
$command="Access http://$frontFQDN and input some data to the database via menu create "
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Create Azure MySQL Service. [Already created]"
$command="az mysql server create -l southeastasia -g $resourceGroupName -n 'mysqlxx$suffix' -u $mysqlAdmin -p $dbPassword --sku-name B_Gen5_1 --version 5.7 --output table"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Allow Azure Service to access Azure MySQL Sevice. This is just for DMS for online DB migration."
$command="az mysql server firewall-rule create -g $resourceGroupName -s 'mysqlxx$suffix' -n allazureip --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0 --output table"
excec-Command $command $step $isManual $isPrompt $description

#$localMachineIP = az vm show -d -g $resourceGroupName -n $localMachineName --query publicIps -o tsv

$isManual='false'
$step=$step+1
$description = "Allow on-premise local machine to access Azure MySQL Server. This is for importing DB schema."
$command="az mysql server firewall-rule create -g $resourceGroupName -s mysqlxx$suffix -n localmachineip --start-ip-address $localMachineIP --end-ip-address $localMachineIP --output table"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Export DB schema from on premise MySQL."
$command="mysqldump -h localhost -uroot -p$dbPassword --databases movies --protocol TCP --no-data --result-file=$scriptRoot/mysql/movies.sql"
excec-Command $command $step $isManual $isPrompt $description


$isManual='true'
$step=$step+1
$description = "Import DB schema to Azure MySQL Service."
$command="mysql -umysqladmin$suffix@mysqlxx$suffix -p$dbPassword -h mysqlxx$suffix.mysql.database.azure.com < /workspace/SimpleDotnetMysql/kubescript/deployKube/mysql/movies.sql"
excec-Command $command $step $isManual $isPrompt $description
set-mysqlImport $suffix $dbPassword $tempDir
Invoke-Expression "/workspace/SimpleDotnetMysql/kubescript/deployKube/temp/mysqlImport"

$isManual='false'
$step=$step+1
$description = "Verify the imported schema of Azure MySQL Service."
$command="mysql -umysqladmin$suffix@mysqlxx$suffix -p$dbPassword -h mysqlxx$suffix.mysql.database.azure.com -e 'show databases;' "
excec-Command $command $step $isManual $isPrompt $description

$localmachinesubnetId = az network vnet subnet list --resource-group $resourceGroupName --vnet-name $vnetName --query "[?name=='$localMachineSubnet'].id" | ConvertFrom-Json

$isManual='true'
$step=$step+1
$description = "Create Azure DMS Service. This is for online database migration. [Already created]"
$command="az dms create -l southeastasia -n dms-$suffix -g $resourceGroupName --sku-name Premium_4vCores --subnet $localmachinesubnetId"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Create DMS project and task for online DB migration."
$command="Create dms project and task by Azure Portal with following parameters:

New migration project
====================
Project name: dmsproject-$suffix
Source server type: MySQL
Target server type: Azure Database for MySQL
Choose type for activity: Online data migration

Select source
============
Source Server Name: $frontFQDN
Server port: 3306
User Name: root
Password: $dbPassword

Select target
=============
Target Server Name: mysqlxx$suffix.mysql.database.azure.com
User Name: mysqladmin$suffix@mysqlxx$suffix
Password: $dbPassword

Select databases
================
Database: movies

Configure migration settings
=============
Leave as default.

Summary
=======
Activity name: runnowtask
"

excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Verify full DB sync."
$command="Open azure portal and observe full sync from DMS project activity."
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Verify full synced data in Azure MySQL Service."
$command="mysql -umysqladmin$suffix@mysqlxx$suffix -p$dbPassword -h mysqlxx$suffix.mysql.database.azure.com -e 'select * from movies.movies;' "
excec-Command $command $step $isManual $isPrompt $description


$isManual='true'
$step=$step+1
$description = "Create data for incremental sync"
$command="Access http://$frontFQDN and insert more data."
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Verify incremental sync."
$command="Open azure portal and observe incremental sync from dms project activity."
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Verify incremental synced data in Azure MySQL Service."
$command="mysql -umysqladmin$suffix@mysqlxx$suffix -p$dbPassword -h mysqlxx$suffix.mysql.database.azure.com -e 'select * from movies.movies;' "
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Create Storage Account for Blob storage. This is for static objects migration e.g. images, vdo clips."
$command="az storage account create -n storageaccountxx$suffix -g $resourceGroupName -l southeastasia --sku Standard_LRS --output table"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Create Blob container in Storage Account. This is for static objects migration e.g. images, vdo clips."
$command="az storage container create -n aksblobcontainer$suffix --account-name storageaccountxx$suffix --public-access blob --output table"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Get Storage Account key. This is for blob container access  to upload files."
$command="az storage account keys list -g $resourceGroupName  -n storageaccountxx$suffix --query [0].value "
$accountKey=excec-Command-ReturnV $command $step $isManual $isPrompt $description
$accountKey = [string]::join("",($accountKey.Split("`n")))   # To remove newline

$isManual='false'
$step=$step+1
$description = "Upload the image file to blob container. This is the image on the home page."
$command="az storage blob upload -f /workspace/SimpleDotnetMysql/MvcMovie/wwwroot/images/microsoft-azure-logo.jpg -c aksblobcontainer$suffix -n microsoft-azure-logo.jpg --account-key $accountKey --account-name storageaccountxx$suffix --output table"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Verify the original home page code (index.cshtml). See that the image is accessed from local disk."
$command="cat /workspace/SimpleDotnetMysql/MvcMovie/Views/Home/Index.cshtml"
excec-Command $command $step $isManual $isPrompt $description

$GreetingMessage = "Welcome"
set-homeFrontend $microServiceDir $suffix $GreetingMessage

$isManual='false'
$step=$step+1
$description = "Verify the new home page code (index.cshtml). See that the image is accessed from Azure blob container."
$command="cat $microServiceDir/MvcMovie/Views/Home/Index.cshtml"
excec-Command $command $step $isManual $isPrompt $description


#$kubeDockerFileDir = @('moviesAPI_get','moviesAPI_detail', 'moviesAPI_create', 'moviesAPI_edit', 'moviesAPI_delete', 'MvcMovie')
#$kubePort = @('7771', '7772', '7773', '7774', '7775')
#$kubeName= @('apiget', 'apidetail', 'apicreate', 'apiedit', 'apidelete', 'mvcmoviefrontend')

#Copy-Item $microServiceDir/tempCodes/appsettings.json_original  -Destination $microServiceDir/moviesAPI_get/appsettings.json
Copy-Item $microServiceDir/tempCodes/Startup.cs_original  -Destination $microServiceDir/moviesAPI_get/Startup.cs


For ($i=0; $i -lt $kubePort.count; $i++) {

    set-Appsettings $suffix $microServiceDir $kubeDockerFileDir[$i] $kubePort[$i]
  
}

$isManual='false'
$step=$step+1
$description = "Review Dockerfile of apiget. Verify the multi-stage build."
$command="cat $microServiceDir/$($kubeDockerFileDir[0])/Dockerfile"
excec-Command $command $step $isManual $isPrompt $description


For ($i=0; $i -lt $kubeName.count; $i++) {

    #$isManual='false'
    #$step=$step+1
    #$command="set-Location  $microServiceDir/$($kubeDockerFileDir[$i])"
    #excec-Command $command $step $isManual $isPrompt

    set-Location  $microServiceDir/$($kubeDockerFileDir[$i])

    

    $isManual='false'
    $step=$step+1
    $tag ="v1.0"
    $description = "Build Docker image of $($kubeName[$i]) based on Dockerfile."
    $command="docker build -t $($kubeName[$i]):$tag ."
    excec-Command $command $step $isManual $isPrompt $description

    $isManual='false'
    $step=$step+1
    $tag ="v1.0"
    $description = "Tag Docker image based the requirement of Azure Container Registry."
    $command="docker tag $($kubeName[$i]):$tag $acrName.azurecr.io/repo/$($kubeName[$i]):$tag"
    excec-Command $command $step $isManual $isPrompt $description
}


$isManual='false'
$step=$step+1
# $command="docker image ls $acrName.azurecr.io/repo/$($kubeName[$i]) "
$description = "Verify all built Docker images on local repository."
$command="docker image list acrforaks*.azurecr.io/repo/*"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Create Azure Container Registry (ACR). [Already created]"
$command="az acr create --resource-group $resourceGroupName --name $acrName --sku Basic --output table"
$acr= excec-Command-ReturnV $command $step $isManual $isPrompt $description
$acr = [string]::join("",($acr.Split("`n")))   # To remove newline


$isManual='false'
$step=$step+1
$description = "Authenticate ACR. This is for Docker images upload."
$command="az acr login --name $acrName --output table"
excec-Command $command $step $isManual $isPrompt $description



For ($i=0; $i -lt $kubeName.count; $i++) {
    $isManual='false'
    $step=$step+1
    $description = "Upload $($kubeName[$i]) Dokcer image."
    $command="docker push $acrName.azurecr.io/repo/$($kubeName[$i])"
    excec-Command $command $step $isManual $isPrompt  $description
} 

$isManual='false'
$step=$step+1
$description = "Verify uploaded Docker image in ACR."
$command="az acr repository list -n $acrName --output table"
excec-Command $command $step $isManual $isPrompt $description

#$subnetId = az network vnet subnet list --resource-group $resourceGroupName --vnet-name $vnetName --query "[0].id" --output tsv
$subnetId = az network vnet subnet list --resource-group $resourceGroupName --vnet-name $vnetName --query "[?contains (name,'$clusterSubnetName')].id" --output tsv

$subnetId = [string]::join("",($subnetId.Split("`n")))   # To remove newline

$isManual='true'
$step=$step+1
$description = "Create Azure kubernetes Service (AKS). [Already created]"
$command="az aks create -n $aksName -g $resourceGroupName --kubernetes-version $aksVersion --node-count 1 --attach-acr $acrName --enable-managed-identity --network-plugin azure --vnet-subnet-id $subnetId --docker-bridge-address $dockerBridgeAddress --dns-service-ip $dnsServiceIP --service-cidr $serviceCIDR --max-pods 60| ConvertFrom-Json"
excec-Command $command $step $isManual $isPrompt $description

#$isManual='false'
#$step=$step+1
#$command="az aks enable-addons -a monitoring -n $aksName -g $resourceGroupName"
#excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$description = "Get AKS credential for further AKS access."
$command="az aks get-credentials --resource-group $resourceGroupName --name $aksName --overwrite-existing --output table"
excec-Command $command $step $isManual $isPrompt $description



#$kubeDockerFileDir = @('moviesAPI_get','moviesAPI_detail', 'moviesAPI_create', 'moviesAPI_edit', 'moviesAPI_delete', 'MvcMovie')
#$kubePort = @('7771', '7772', '7773', '7774', '7775', '80')
#$kubeName= @('apiget', 'apidetail', 'apicreate', 'apiedit', 'apidelete', 'mvcmoviefrontend')



For ($i=0; $i -lt $kubeName.count; $i++) {

    if ($($kubeName[$i]) -match "API"){
         $kubeServiceType="ClusterIP"
         $kubeTier="api"
         

    } 
    else {
         $kubeServiceType="LoadBalancer"
         $kubeTier="frontend"
         
    }
    $tag ="v1.0"
    $cpuRequest = "100m"
    $cpuLimit = "1000m"
    $changeCause = "initial Deployment with version 1.0"
    set-Deployment $acrName $tempDir $($kubeName[$i])  $kubeTier  $($kubePort[$i]) $tag $cpuRequest $cpuLimit $changeCause

    if ($i -eq 0 ){

    $isManual='false'
    $step=$step+1
    $description = "Review deployment manifest file (yaml) of $($kubeName[$i]). Observe the following:
                    1. image name and its repository.
                    2. Label of the template."
    $command="cat $tempDir/deploy-$($kubeName[$i]).yaml"
    excec-Command $command $step $isManual $isPrompt $description
    
    }

    $isManual='false'
    $step=$step+1
    $description = "Deploy $($kubeName[$i]) based on the configuration in manifest file."
    $command="kubectl apply -f $tempDir/deploy-$($kubeName[$i]).yaml "
    excec-Command $command $step $isManual $isPrompt $description
    

    set-Service $tempDir $($kubeName[$i]) $kubeTier $($kubePort[$i]) $kubeServiceType $suffix $frontendServiceName

    if ($i -eq 0 ){

    $isManual='false'
    $step=$step+1
    $description = "Review service manifest file (yaml) of $($kubeName[$i]). Observe selector."
    $command="cat $tempDir/service-$($kubeName[$i]).yaml"
    excec-Command $command $step $isManual $isPrompt $description 

    }
    
    $isManual='false'
    $step=$step+1
    $description = "Deploy $($kubeName[$i]) service based on the configuration in manifest file."
    $command="kubectl apply -f $tempDir/service-$($kubeName[$i]).yaml"
    excec-Command $command $step $isManual $isPrompt $description 
}

$isManual='true'
$isPrompt ='false'
$step=$step+1
$description = "Wait for few seconds... This to allow load balancer (service of frontend) to get public IP"
$command="...."
excec-Command $command $step $isManual $isPrompt $description
$isPrompt ='true'

$lbIP = "<pending>"
while ($lbIP -eq "<pending>"){
$arrayString = kubectl get service/mvcmoviefrontend$suffix |  Select-String -Pattern LoadBalancer
$arrayString = $arrayString -split '\s+'
$lbIP = $arrayString[3]
sleep 3
}

$isManual='false'
$step=$step+1
$description = "Verifiy the current setup of AKS. Observe and note public IP address of service of frontend."
$command="kubectl get all"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Create Traffic Manager. This is for redirect traffic from users to new system on AKS or redirect traffic back to on-premise for rollback plan."
$command="az network traffic-manager profile create -g $resourceGroupName -n 'Tm-$suffix' --routing-method Priority --unique-dns-name 'tmx-$suffix' --ttl 10 --protocol HTTP --port 80 --path '/' --output table"
excec-Command $command $step $isManual $isPrompt $description $description

$isManual='false'
$step=$step+1
$description = "Set the first Traffic Manager endpoint to web application on-premise with low number of priority (but higher priority)."
#$command="az network traffic-manager endpoint create -g $resourceGroupName --profile-name 'Tm-$suffix' -n onpremise --type externalEndpoints --target $localMachineName.southeastasia.cloudapp.azure.com --endpoint-status enabled --priority 1 --output table"
$command="az network traffic-manager endpoint create -g $resourceGroupName --profile-name 'Tm-$suffix' -n onpremise --type externalEndpoints --target $localMachineIP --endpoint-status enabled --priority 1 --output table"
excec-Command $command $step $isManual $isPrompt $description

#$arrayString = kubectl get service/mvcmoviefrontend$suffix |  Select-String -Pattern LoadBalancer
#$arrayString = $arrayString -split '\s+'

$isManual='false'
$step=$step+1
$description = "Set the second Traffic Manager endpoint to web application on AKS with high number of priority (but lower priority)."
#$command="az network traffic-manager endpoint create -g $resourceGroupName --profile-name 'Tm-$suffix' -n oncloud --type externalEndpoints --target $frontendServiceName.southeastasia.cloudapp.azure.com --endpoint-status enabled --priority 2 --output table"
$command="az network traffic-manager endpoint create -g $resourceGroupName --profile-name 'Tm-$suffix' -n oncloud --type externalEndpoints --target $lbIP --endpoint-status enabled --priority 2 --output table"
excec-Command $command $step $isManual $isPrompt $description

## TO DO - change domain name to happylab$suffix.ml

$isManual='false'
$step=$step+1
$description = "Delete A record that directly point to local system of $websiteName."
$command="az network dns record-set a delete --name $websiteName --resource-group $resourceGroupName --zone-name $domainName --yes"
excec-Command $command $step $isManual $isPrompt $description

systemd-resolve --flush-caches

$isManual='false'
$step=$step+1
$description = "Create CNAME record object of $websiteName."
$command="az network dns record-set cname create --name $websiteName --resource-group $resourceGroupName --ttl 10 --zone-name $domainName --output table"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Associate CNAME record object to Public IP of Traffic Manager. Then let Traffic Manager decides which IP (on-premise or AKS) will be returned to users based on priority."
$command="az network dns record-set cname set-record -g $resourceGroupName -z $domainName -n $websiteName -c tmx-$suffix.trafficmanager.net --ttl 10 --output table"
excec-Command $command $step $isManual $isPrompt $description

systemd-resolve --flush-caches

$isManual='true'
$isPrompt ='false'
$step=$step+1
$description = "Wait for few seconds... to allow the existing DNS cache expires (TTL = 10 seconds)"
$command="...."
excec-Command $command $step $isManual $isPrompt $description
$isPrompt ='true'

sleep 30

#$isManual='false'
#$step=$step+1
#$command="sleep 30"
#excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$description = "Verify that we still get public IP address of on-premise system. However via CNAME that pointed to Traffic Manager."
$command="nslookup $frontFQDN"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Verify that we still access to website. You may need to wait a bit depends on your TTL DNS cache of your laptop. manually clear cache may require (ipconfig/flushdns)."
$command="Access http://$frontFQDN"
excec-Command $command $step $isManual $isPrompt $description

Set-Location $mvcmovieDir

$isManual='false'
$step=$step+1
$description = "Now it's time to excute migration cutover. First we need to ensure that there is no traffic from the users (e.g. temp. shutdown web or put in underconstruction mode.)"
$command="pkill MvcMovie"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Verify that we cannot access the website anymore."
$command="Access http://$frontFQDN"
excec-Command $command $step $isManual $isPrompt $description

$isManual='ture'
$step=$step+1
$description = "Cutover Database migration."
$command="Go to DMS on Azure portal. Ensure that the status is ""ready to cutover"" and then click cutover."
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Redirect users traffic to web on AKS by setting the number of priority of on-premise of Taffic Manager to be higher than AKS. This makes on-premise lower priority."
$command="az network traffic-manager endpoint create -g $resourceGroupName --profile-name 'Tm-$suffix' -n onpremise --type externalEndpoints --target $localMachineIP --endpoint-status enabled --priority 10 --output table"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$isPrompt ='false'
$step=$step+1
$description = "Wait for few seconds... to allow the existing DNS cache expires (TTL = 10 seconds)"
$command="...."
excec-Command $command $step $isManual $isPrompt $description
$isPrompt ='true'

sleep 30

$isManual='false'
$step=$step+1
$description = "Verify that we get public IP address of load balancer of AKS (point to frontend) still via CNAME that pointed to Traffic Manager."
$command="nslookup $frontFQDN"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Verify that we access to website on AKS. You may need to wait a bit depends on your TTL DNS cache of your laptop. manually clear cache may require (ipconfig/flushdns)."
$command="Access http://$frontFQDN"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Once the migration has been successfully migrated and tested. 
                Traffic Manager is not required anymore (as we planned to use for migration and rollback).
                Therefore, it should be removed.
                Frist, remove CNAME that pointed to Traffic Manager."
$command="az network dns record-set cname delete --name $websiteName --resource-group $resourceGroupName --zone-name $domainName --yes"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Create new A record object for $websiteName."
$command="az network dns record-set a create --name $websiteName --resource-group $resourceGroupName --ttl 10 --zone-name $domainName --output table"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Associate A record to IP address of load balancer of AKS (pointed to frontend)"
$command="az network dns record-set a add-record -g $resourceGroupName -z $domainName -n $websiteName -a $lbIP --ttl 10 --output table"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$isPrompt ='false'
$step=$step+1
$description = "Wait for few seconds... to allow the existing DNS cache expires (TTL = 10 seconds)"
$command="...."
excec-Command $command $step $isManual $isPrompt $description
$isPrompt ='true'

sleep 30

$isManual='false'
$step=$step+1
$description = "Verify that we get public IP address of load balancer of AKS (point to frontend) directly (not via Traffic Manager)."
$command="nslookup $frontFQDN"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Verify that we access to website on AKS. You may need to wait a bit depends on your TTL DNS cache of your laptop. manually clear cache may require (ipconfig/flushdns)."
$command="Access http://$frontFQDN"
excec-Command $command $step $isManual $isPrompt $description


$isManual='false'
$step=$step+1
$description = "Delete Traffic Manager."
$command="az network traffic-manager profile delete -g $resourceGroupName -n Tm-$suffix --output table"
excec-Command $command $step $isManual $isPrompt $description


$isManual='true'
$step=$step+1
$description = "Congratulations!!! You have just completed the following:
                1. Migrated MySQL Database from on-premise to Azure MySQL service with small downtime period and automated process.
                2. Migrated static files e.g. images to blob storage. 
                3. Changed monolithic app to microservice app as Docker images based on configuration in Docker file.
                4. Uploaded Docker images to ACR.
                5. Deployed microservice app to AKS based on the configuration of yaml files.
                6. Redirected user traffic from on-premise to AKS with Traffic with small downtime and rollback plan.
                "
$command="..."
excec-Command $command $step $isManual $isPrompt $description

Set-Location $SectionRoot



