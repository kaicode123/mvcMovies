Write-output "Deleting All Provisioned Resources by section02.ps1... " "`n" 

. /workspace/SimpleDotnetMysql/kubescript/deployKube/aks-keyvault_withoutdotgit/initParameters.ps1
az acr login -n $acrName 

$serviceName = $kubeName[5]
#kubectl delete -f $tempDir/hpa2-$serviceName.yaml
kubectl delete -f $tempDir/hpa-$serviceName.yaml
az aks update --resource-group $resourceGroupName --name $aksName --disable-cluster-autoscaler
