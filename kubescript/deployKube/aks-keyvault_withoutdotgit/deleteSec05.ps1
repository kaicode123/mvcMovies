Write-output "Deleting All Provisioned Resources by section02.ps1... " "`n" 

. /workspace/SimpleDotnetMysql/kubescript/deployKube/aks-keyvault_withoutdotgit/initParameters.ps1
az acr login -n $acrName
kubectl delete -f $tempDir/podTest.yaml

az keyvault delete -n $keyVaultName -g $resourceGroupName 
kubectl delete -f $tempDir/SecretProviderClass.yaml
helm uninstall csi-azure --namespace csi-driver
kubectl delete -f $tempDir/addpodidentity.yaml
helm uninstall pod-identity 

az identity delete -g $resourceGroupName -n $identityName2
Copy-Item $microServiceDir/tempCodes/appsettings.json_original  -Destination $microServiceDir/moviesAPI_get/appsettings.json
Copy-Item $microServiceDir/tempCodes/Startup.cs_original  -Destination $microServiceDir/moviesAPI_get/Startup.cs

$i = 0
#$command="kubectl delete -f $tempDir/deploy-$($kubeName[$i]).yaml"
#excec-Command $command $step $isManual 'false'
<#
$tag ="v1.0"
$cpuRequest = "100m"
$cpuLimit = "1000m"
$changeCause = "initial Deployment with version 1.0"
set-Deployment $acrName $tempDir $($kubeName[$i])  $kubeTier  $($kubePort[$i]) $tag $cpuRequest $cpuLimit $changeCause

$command="cat $tempDir/deploy-$($kubeName[$i]).yaml"
excec-Command $command $step $isManual 'false'

$command="kubectl apply -f $tempDir/deploy-$($kubeName[$i]).yaml "
excec-Command $command $step $isManual 'false'
#>
