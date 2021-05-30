write-output "Welcome to LAB Section#4 Rollout and rollback your applications in AKS" "`n" 

### Send Hey before upgrade, then upgrade, observe hey that no 502

. /workspace/SimpleDotnetMysql/kubescript/deployKube/aks-keyvault_withoutdotgit/initParameters.ps1
az acr login -n $acrName

$isPrompt = 'true'

## -------------------------------------------------------------------

# Gen load -----------------------------------------------
 #hey -c 10 -q 10 -z 30m https://$frontFQDN /

$isManual='true'
$step=$step+1
$description = "Simulate 5 web clients to generate traffic at 30 requests/second.
                This might cause hpa triggered. So the new number of frontend pods should be 5-6"
$command="Open new terminal and execute: hey -c 5 -q 30 -z 30m http://$frontFQDN"
excec-Command $command $step $isManual $isPrompt $description

#$isManual='false'
#$step=$step+1
#$description = "Observe number of replica of running mvcmoviefrontend and the state"
#$command="kubectl get pods"
#$isOK = 'g'
#excec-Command $command $step $isManual $isPrompt $description
#while ($isOK -eq 'g'){
#excec-Command $command $step $isManual 'false'
#$isOK = read-Host -prompt "Press 'g' to rerun this command or press 'y' to move to next step"
#}


# Rolling update -----------------------------------------
$GreetingMessage = "Welcome YoYo9!!!"
set-homeFrontend $microServiceDir $suffix $GreetingMessage

$isManual='false'
$step=$step+1
$description = "We modify greeting message of our home page a bit. (Welcome > Welcome YoYo9!!!)"
$command="cat $microServiceDir/MvcMovie/Views/Home/Index.cshtml"
excec-Command $command $step $isManual $isPrompt $description

$i = 5

#$step=$step+1
#$command="set-Location  $microServiceDir/$($kubeDockerFileDir[$i])"
#excec-Command $command $step $isManual $isPrompt
set-Location  $microServiceDir/$($kubeDockerFileDir[$i])

$isManual='false'
$step=$step+1
$tag ="v2.0"
$description = "Build new Docker image to reflect the modification."
$command="docker build -t $($kubeName[$i]):$tag ."
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$tag ="v2.0"
$description = "Tag and up Docker image version to V2.0"
$command="docker tag $($kubeName[$i]):$tag $acrName.azurecr.io/repo/$($kubeName[$i]):$tag"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Push Docker image to ACR."
$command="docker push $acrName.azurecr.io/repo/$($kubeName[$i])"
excec-Command $command $step $isManual $isPrompt $description

$kubeTier="frontend"
$cpuRequest = "100m"
$cpuLimit = "1000m"
$tag ="v2.0"
$changeCause = "Update tilte to YoYo9!!!"
set-DeploymentRollingUpdate $acrName $tempDir $($kubeName[$i])  $kubeTier  $($kubePort[$i]) $tag $cpuRequest $cpuLimit $changeCause

$isManual='false'
$step=$step+1
$description = "Review new deployment manifest file. Observe the followings:
                - ChangeCause is set to Update title to YoYo9!!!. This will be added as rollout history.
                - MaxSurge (1) maxUnavailable (25%)
                - Readiness Probe. Whether pod is ready to get traffic. 
                   - check http/80 after starts pod at 5 seconds and check every 5 second.
                   - if success rate hits 1. Consider pod is ready.
                "
$command="cat $tempDir/deploy-$($kubeName[$i]).yaml"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Rollout new frontend app with the change of greeting message."
$command="kubectl apply -f $tempDir/deploy-$($kubeName[$i]).yaml"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Observe rollout status. New pods are replacing old pods with the predefined rollout criteria."
$command="kubectl rollout status deployment.apps/mvcmoviefrontend"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Verify new greeting message on home page"
$command="Access http://$frontFQDN"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Observe http return status code. It should be 200 [ok]. No connection loss."
$command="Terminate hey by pressing ctrl + C and then observe http status code"
excec-Command $command $step $isManual $isPrompt $description


# Rollback -----------------------------------------
 #kubectl rollout history   deployment.apps/mvcmoviefrontend

$isManual='true'
$step=$step+1
$description = "Simulate 5 web clients to generate traffic at 30 requests/second."
$command="Open new terminal and execute: hey -c 5 -q 30 -z 30m http://$frontFQDN"
excec-Command $command $step $isManual $isPrompt $description


$GreetingMessage = "asf;ajfaoeiurfalds;f"
set-homeFrontend $microServiceDir $suffix $GreetingMessage

$isManual='false'
$step=$step+1
$description = "There is typo of greeting message for new version of app (without notice)."
$command="cat $microServiceDir/MvcMovie/Views/Home/Index.cshtml"
excec-Command $command $step $isManual $isPrompt $description

$i = 5

#$step=$step+1
#$command="set-Location  $microServiceDir/$($kubeDockerFileDir[$i])"
#excec-Command $command $step $isManual $isPrompt

set-Location  $microServiceDir/$($kubeDockerFileDir[$i])

$isManual='false'
$step=$step+1
$tag ="v3.0"
$description = "Build new Docker image to reflect the modification."
$command="docker build -t $($kubeName[$i]):$tag ."
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$tag ="v3.0"
$description = "Tag and up Docker image version to V3.0"
$command="docker tag $($kubeName[$i]):$tag $acrName.azurecr.io/repo/$($kubeName[$i]):$tag"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Push Docker image to ACR."
$command="docker push $acrName.azurecr.io/repo/$($kubeName[$i])"
excec-Command $command $step $isManual $isPrompt $description 

$kubeTier="frontend"
$cpuRequest = "100m"
$cpuLimit = "1000m"
$tag ="v3.0"
$changeCause = "Update Something."
set-DeploymentRollingUpdate $acrName $tempDir $($kubeName[$i])  $kubeTier  $($kubePort[$i]) $tag $cpuRequest $cpuLimit $changeCause

$isManual='false'
$step=$step+1
$description = "Review new deployment manifest file. Observe changeCause."
$command="cat $tempDir/deploy-$($kubeName[$i]).yaml"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Rollout new frontend app with the change of(typo) greeting message."
$command="kubectl apply -f $tempDir/deploy-$($kubeName[$i]).yaml"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Observe rollout status. New pods are replacing old pods with the predefined rollout criteria."
$command="kubectl rollout status deployment.apps/mvcmoviefrontend"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Verify new greeting message on home page. That is typo!!!"
$command="Access http://$frontFQDN"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Let's review rollout history."
$command="kubectl rollout history deployment mvcmoviefrontend"
excec-Command $command $step $isManual $isPrompt $description

$history =  kubectl rollout history deployment mvcmoviefrontend
$lines = $history | Measure-Object -Line
$currentRevision = $lines.lines - 2 
$RolloutRevision = $currentRevision - 1

$isManual='false'
$step=$step+1
$description = "Pickup the latest update one (the one before the typo) for rollback."
$command="kubectl rollout undo deployment mvcmoviefrontend --to-revision=$RolloutRevision"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Observe rollback status. We are now reversing to the good one with rollout criteria."
$command="kubectl rollout status deployment.apps/mvcmoviefrontend"
excec-Command $command $step $isManual $isPrompt $description 

$isManual='true'
$step=$step+1
$description = "Verify the greeting message on home page. It should be correct now."
$command="Access web: https://$frontFQDN"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Observe http return status code. It should be 200 [ok]. No connection loss."
$command="Terminate hey by pressing ctrl + C and then observe http status code"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Congratulations!!! You have just completed the following:
                1. Automated rollout new application (pod) without the connection loss.
                2. Automated rollback malfunction application (pod) to the previous version without the connection loss.
                "
$command="..."
excec-Command $command $step $isManual $isPrompt $description

Set-Location $SectionRoot

# -------------------------------
#>

