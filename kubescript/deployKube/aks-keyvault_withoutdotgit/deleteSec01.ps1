Write-output "Deleting All Provisioned Resources... " "`n" 

. /workspace/SimpleDotnetMysql/kubescript/deployKube/aks-keyvault_withoutdotgit/initParameters.ps1

# Section Delete resource ----------------------------
kubectl delete deployment.apps/apicreate deployment.apps/apidelete deployment.apps/apidetail deployment.apps/apiedit deployment.apps/apiget deployment.apps/mvcmoviefrontend
kubectl delete service/apicreate service/apidelete service/apidetail service/apiedit service/apiget service/mvcmoviefrontendb

az network dns record-set a delete --name $websiteName --resource-group $resourceGroupName --zone-name $domainName --yes
az network dns record-set cname delete --name $websiteName --resource-group $resourceGroupName --zone-name $domainName --yes
systemd-resolve --flush-caches
az network traffic-manager profile delete -g $resourceGroupName -n "Tm-$suffix" 
az group delete --name ""MC_"$resourceGroupName"_"$aksName"_"$location"  --yes
az aks delete --name $aksName -g $resourceGroupName --yes
az mysql server delete -g $resourceGroupName -n "mysqlxx$suffix"  --yes
az storage account delete -n "storageaccountxx$suffix" -g $resourceGroupName --yes
az acr delete --name $acrName --yes
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
#docker image prune -a -f
pkill MvcMovie

Write-output "`n" 
Write-output "All Provisioned Resources Deleted. "
Write-output "Please delete DMS Project Task manually by Azure Portal." "`n" 

Set-Location $SectionRoot


