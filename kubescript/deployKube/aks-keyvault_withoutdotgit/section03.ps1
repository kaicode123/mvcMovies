write-output "Welcome to LAB Section#3 Scale your pods and nodes" "`n" 

. /workspace/SimpleDotnetMysql/kubescript/deployKube/aks-keyvault_withoutdotgit/initParameters.ps1

$isPrompt = 'true'

$i = 5 # ----mvcmoviefrontend
$cpuRequest = "30m"
$cpuLimit = "50m"
$tag ="v1.0"
$kubeTier="frontend"
$changeCause = "To easier simulate the pod scale out, reduce cpu request from 100m to 30m and cpu limit from 1000m to 50m"
set-Deployment $acrName $tempDir $($kubeName[$i])  $kubeTier  $($kubePort[$i]) $tag $cpuRequest $cpuLimit $changeCause

$isManual='false'
$step=$step+1
$description = "Reconfigure cpu request from 100m to 30m and cpu limit from 1000m to 50m."
$command="cat $tempDir/deploy-$($kubeName[$i]).yaml"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Apply new manifest file for mvcmoviefrontend"
$command="kubectl apply -f $tempDir/deploy-$($kubeName[$i]).yaml "
excec-Command $command $step $isManual $isPrompt $description

# TO do -  print yaml of mvcmoviefrontend
#$isManual='false'
#$step=$step+1
#$command="cat $tempDir/service-mvcmoviefrontend.yaml"
#excec-Command $command $step $isManual $isPrompt

# ------- Manual scale
$isManual='false'
$step=$step+1
$description = "Observe number of replica of running mvcmoviefrontend."
$command="kubectl get all"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Manually scale in number of replica of mvcmoviefrontend to 10 (scale out)"
$command="kubectl scale  --replicas=10 deployment.apps/mvcmoviefrontend"
excec-Command $command $step $isManual $isPrompt $description


$isManual='false'
$step=$step+1
$description = "Observe number of replica of running mvcmoviefrontend and the state"
$command="kubectl get pods"
$isOK = 'g'
excec-Command $command $step $isManual $isPrompt $description
while ($isOK -eq 'g'){
excec-Command $command $step $isManual 'false'
$isOK = read-Host -prompt "Press 'g' to rerun this command or press 'y' to move to next step"
}

$isManual='false'
$step=$step+1
$description = "Manually scale number of replica of mvcmoviefrontend to 1 (scale in)"
$command="kubectl scale  --replicas=1 deployment.apps/mvcmoviefrontend"
excec-Command $command $step $isManual $isPrompt $description 


$isManual='false'
$step=$step+1
$description = "Observe number of replica of running mvcmoviefrontend and the state"
$command="kubectl get pods"
$isOK = 'g'
excec-Command $command $step $isManual $isPrompt $description
while ($isOK -eq 'g'){
excec-Command $command $step $isManual 'false'
$isOK = read-Host -prompt "Press 'g' to rerun this command or press 'y' to move to next step"
}

# ------- Auto Sacle Pods

$serviceName = $kubeName[5]
#set-Hpa $tempDir $serviceName
set-Hpa2 $tempDir $serviceName


$isManual='false'
$step=$step+1
$description = "Review horizontal pod autoscaler manifest file for autoscaling management.
                Observe threshold for scale in/out."
$command="cat $tempDir/hpa-$serviceName.yaml"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Deploy horizontal pod autoscaler manifest file for autoscaling management."
$command="kubectl apply -f $tempDir/hpa-$serviceName.yaml"
excec-Command $command $step $isManual $isPrompt $description 





$isManual='true'
$step=$step+1
$description = "Let's test and observe hpa autoscaler."
$command="Open 3 more terminals:
          Terminal 1 > execute: hey -c 500 -z 30m  http://$frontFQDN
          Terminal 2 > observe replicaset by executing: kubectl get replicaset -w  to see desired, current and ready pod.
          Terminal 3 > observe hpa status by executing: kubectl get hpa -w  to see current and baseline loads"

excec-Command $command $step $isManual $isPrompt $description

$pendingPods = (kubectl get pod --selector app=mvcmoviefrontend | Select-String -Pattern "Pending")
$pendingPod = $pendingPods.GetValue(0)
$pendingPod = $pendingPod -split '\s+'
$pendingPodName =  $pendingPod[0]

$isManual='false'
$step=$step+1
$description = "Let's see the root cause why pod stop scaling to meet desired number."
$command="kubectl describe pod $pendingPodName"
excec-Command $command $step $isManual $isPrompt $description
    

# ------- Auto Sacle Node

$isManual='false'
$step=$step+1
$description = "Notice that pod cannot scale anymore to meet the desired number as node resource reaches maximum capacity.
                So we need to expand maximum number of node for AKS cluster. [default:1 and max:3]"
$command="az aks update --resource-group $resourceGroupName --name $aksName --enable-cluster-autoscaler   --min-count 1 --max-count 3 --cluster-autoscaler-profile scale-down-delay-after-add=3m scale-down-unneeded-time=3m scale-down-unready-time=3m"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Observe cluster autoscaler."
$command="Open new terminal and execute: kubectl get node -w" 
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Observe number of Desired , Current and Ready of pod"
$command="Open new terminal and execute: kubectl get pod -w" 
excec-Command $command $step $isManual $isPrompt $description

# (Auto scale in pod/node) ------------------

$isManual='true'
$step=$step+1
$description = "Terminate the load."
$command="Terminate hey by pressing ctrl + c"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Both pods and nodes are scaling in automatically as load has stopped."
$command = "Observe the followings:
            Terminal that running kubectl get replicaset -w 
            Terminal that running kubectl get hpa -w
            Terminal that running kubectl get node  -w"
excec-Command $command $step $isManual $isPrompt $description


$isManual='true'
$step=$step+1
$description = "Congratulations!!! You have just completed the following:
                1. Executed manual pod scale in/out.
                2. Executed horizontal pod autoscaler in/out 
                3. Executed cluster auto scaler in/out
                
                * You only pay for additional cost for extra nodes (VM) during the period that cluster scaled up. 
                  Once the cluster scaled down the charge stops. 
                        
                "
$command="..."
excec-Command $command $step $isManual $isPrompt $description

Set-Location $SectionRoot