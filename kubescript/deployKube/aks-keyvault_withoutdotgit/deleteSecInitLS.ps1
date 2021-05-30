Write-output "Deleting All Provisioned Resources... " "`n" 

. /workspace/SimpleDotnetMysql/kubescript/deployKube/aks-keyvault_withoutdotgit/initParameters.ps1

# Section Delete resource ----------------------------

az network dns record-set a delete --name $websiteName --resource-group $resourceGroupName --zone-name $domainName --yes

Set-Location $mvcmovieDir
#dotnet ef migrations remove

docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker volume rm $(docker volume ls -q)
docker image prune -a -f
#



pkill MvcMovie


Set-Location $SectionRoot


