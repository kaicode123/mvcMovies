Write-output "Deleting All Provisioned Resources by section02.ps1... " "`n" 

. /workspace/SimpleDotnetMysql/kubescript/deployKube/aks-keyvault_withoutdotgit/initParameters.ps1
az acr login -n $acrName

$i = 5

$command="kubectl delete -f $tempDir/deploy-$($kubeName[$i]).yaml"
excec-Command $command $step $isManual 'false'

$cpuRequest = "30m"
$cpuLimit = "50m"
$tag ="v1.0"
$kubeTier="frontend"
$changeCause = "Reconfigure cpu request from 100m to 30m and cpu limit from 1000m to 50m"
set-Deployment $acrName $tempDir $($kubeName[$i])  $kubeTier  $($kubePort[$i]) $tag $cpuRequest $cpuLimit $changeCause

$command="kubectl apply -f $tempDir/deploy-$($kubeName[$i]).yaml "
excec-Command $command $step $isManual 'false'