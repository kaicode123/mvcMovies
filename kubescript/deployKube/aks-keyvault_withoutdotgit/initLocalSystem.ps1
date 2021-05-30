Write-output "Initializing local system..." "`n" 

. /workspace/SimpleDotnetMysql/kubescript/deployKube/aks-keyvault_withoutdotgit/initParameters.ps1

$isPrompt='false'

$isManual='false'
$step=$step+1
$command="docker pull mysql:5.7" 
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="docker run --name $mysqlName -e MYSQL_ROOT_PASSWORD=$dbPassword -p 3306:3306 -p 33060:33060  -v $scriptRoot'/mysql/my.cnf:/etc/mysql/my.cnf' -d mysql:5.7"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="docker ps"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="Set-Location $mvcmovieDir" 
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$rand=Get-Random -Maximum 100
$command="dotnet ef migrations add InitialCreate$rand"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="sleep 15"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="dotnet ef database update"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="nohup dotnet run &"
excec-Command $command $step $isManual $isPrompt

# --- ADD A record
$localMachineIP = az vm show -d -g $resourceGroupName -n $localMachineName --query publicIps -o tsv

$isManual='false'
$step=$step+1
$command="az network dns record-set a create --name $websiteName --resource-group $resourceGroupName --ttl 10 --zone-name $domainName --output table"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="az network dns record-set a add-record -g $resourceGroupName -z $domainName -n $websiteName -a $localMachineIP --ttl 10 --output table"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="nslookup $frontFQDN"
excec-Command $command $step $isManual $isPrompt

$isManual='true'
$step=$step+1
$command="write-output 'http://$frontFQDN is ready!!!'"
excec-Command $command $step $isManual $isPrompt

Set-Location $SectionRoot