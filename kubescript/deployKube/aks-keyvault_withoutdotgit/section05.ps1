Write-output "Keyvault integration with AAD pod identity." "`n" 

. /workspace/SimpleDotnetMysql/kubescript/deployKube/aks-keyvault_withoutdotgit/initParameters.ps1

az acr login --name $acrName --output table

$isPrompt = 'true'

$isManual='false'
$step=$step+1
$description = "Review appsettings.json of apiget. There is plain text of mySQL connection String."
$command="cat $microServiceDir/moviesAPI_get/appsettings.json"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Let's store it in more secure way. We will put in Azure Keyvault. First create Keyvault."
$command="az keyvault create -n $keyVaultName -g $resourceGroupName -l $location  --retention-days 7 --enable-soft-delete false | ConvertFrom-Json"
$keyVault = excec-Command-ReturnV $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Put a secret for MySQL connection string in Keyvault."
$command="az keyvault secret set --name $secret2Name --value '$secret2' --vault-name $keyVaultName"
excec-Command $command $step $isManual $isPrompt $description 

#$isManual='false'
#$step=$step+1
#$command="kubectl create ns csi-driver"
#excec-Command $command $step $isManual $isPrompt

#$isManual='false'
#$step=$step+1
#$command="helm repo add csi-secrets-store-provider-azure https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/charts"
#excec-Command $command $step $isManual $isPrompt

#$isManual='false'
#$step=$step+1
#$command="helm install csi-azure csi-secrets-store-provider-azure/csi-secrets-store-provider-azure --namespace csi-driver"
#excec-Command $command $step $isManual $isPrompt

#set-SecretProviderClass $secretProviderClassName $tempDir $keyVaultName $secret2Name $secret2Alias $resourceGroupName $subscriptionId $tenantId

#$isManual='false'
#$step=$step+1
#$command="kubectl create -f $tempDir/SecretProviderClass.yaml"
#excec-Command $command $step $isManual $isPrompt

$aks = az aks show -g $resourceGroupName -n $aksName | ConvertFrom-Json
$kubeletIDclientID = $aks.identityProfile.kubeletidentity.clientId

$isManual='false'
$step=$step+1
$description = "Assign Virtual Machine Contributor roles to kubelet service. This is required for identity management."
$command="az role assignment create --role 'Virtual Machine Contributor' --assignee $kubeletIDclientID --scope /subscriptions/$subscriptionId/resourcegroups/$($aks.nodeResourceGroup)"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Assign Managed Identity Operator roles to kubelet service. This is required for identity management."
$command="az role assignment create --role 'Managed Identity Operator' --assignee $kubeletIDclientID --scope /subscriptions/$subscriptionId/resourcegroups/$($aks.nodeResourceGroup)"
excec-Command $command $step $isManual $isPrompt $description

$identity=$null
while($identity -eq $null) {
#echo "Retrying until Identity is ready..."
$identity = az identity list -g $aks.nodeResourceGroup --query "[?contains(name, 'agentpool')]"  | ConvertFrom-Json                                        
}

$IDPrinID = $identity.principalId
$kvID = $keyVault.id

$IDClientID = $identity.clientId

$isManual='false'
$step=$step+1
$description = "Assign Reader role to Managed Identity of AKS to allow read access for keyvault."
$command="az role assignment create --role Reader --assignee $IDPrinID --scope $kvID"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Assign ""get"" permission to Managed Identity of AKS to allow to get secret from keyvault."
$command="az keyvault set-policy -n $keyVaultName --secret-permissions get --spn $IDClientID"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "We will use AAD-Pod-Identity to implement Managed Identity at pod level. First add helm repo."
$command="helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Now install pod-identity to AKS."
$command="helm install pod-identity aad-pod-identity/aad-pod-identity"
excec-Command $command $step $isManual $isPrompt $description 

set-addpodidentity $identityName $tempDir $identity $identitySelector

$isManual='false'
$step=$step+1
$description = "Review manifest file of AAD Pod identity. Observe
                - ClientID: this associate with Managed Identity that allow to get secret from keyvault
                - Selector: this is the label that will associate to pod that we will authenticate keyvault with MSI."
$command="cat $tempDir/addpodidentity.yaml"
excec-Command $command $step $isManual $isPrompt $description 

$isManual='false'
$step=$step+1
$description = "Deploy AAD Pod Identity."
$command="kubectl apply -f $tempDir/addpodidentity.yaml"
excec-Command $command $step $isManual $isPrompt $description 

#set-podTest $tempDir $secretProviderClassName $identitySelector

#$isManual='false'
#$step=$step+1
#$command="kubectl apply -f $tempDir/podTest.yaml"
#excec-Command $command $step $isManual $isPrompt

#//kubectl exec -it nginx-secrets-store -- ls /mnt/secrets-store/
#kubectl exec -it nginx-secrets-store -- cat /mnt/secrets-store/$secret2Alias


# Deploy MSI of apiget to gather connectionString from keyvault------------------------------------------------

$i = 0
$tag = "v4.0"

Copy-Item $microServiceDir/tempCodes/Startup.cs_original  -Destination $microServiceDir/moviesAPI_get/Startup.cs

$isManual='false'
$step=$step+1
$description = "The current setup, apiget retrieve MySQL connectionString from appsettings.json"
$command="cat $microServiceDir/moviesAPI_get/Startup.cs"
excec-Command $command $step $isManual $isPrompt $description

#$isManual='false'
#$step=$step+1
#$command="Copy-Item $microServiceDir/tempCodes/Startup.cs_keyvault  -Destination $microServiceDir/moviesAPI_get/Startup.cs"
#excec-Command $command $step $isManual $isPrompt

#Copy-Item $microServiceDir/tempCodes/Startup.cs_keyvault  -Destination $microServiceDir/moviesAPI_get/Startup.cs
set-StartupCS-KeyVault $suffix $microServiceDir

$isManual='false'
$step=$step+1
$description = "We change the apiget to retrieve MySQL connectionString from Keyvault instead."
$command="cat $microServiceDir/moviesAPI_get/Startup.cs"
excec-Command $command $step $isManual $isPrompt $description $description 

#$isManual='false'
#$step=$step+1
#$description = "We change the apiget to retrieve MySQL connectionString from Keyvault instead."
#$command="cat $microServiceDir/moviesAPI_get/appsettings.json"
#excec-Command $command $step $isManual $isPrompt $description

#$isManual='false'
#$step=$step+1
#$command="Copy-Item $microServiceDir/tempCodes/appsettings.json_noConnectionString  -Destination $microServiceDir/moviesAPI_get/appsettings.json"
#excec-Command $command $step $isManual $isPrompt

# Copy-Item $microServiceDir/tempCodes/appsettings.json_noConnectionString  -Destination $microServiceDir/moviesAPI_get/appsettings.json

set-Appsettings-NoConnectionString  $suffix $microServiceDir $kubeDockerFileDir[$i] $kubePort[0]

$isManual='false'
$step=$step+1
$description = "Now, we remove connection String from appsettings.json."
$command="cat $microServiceDir/moviesAPI_get/appsettings.json"
excec-Command $command $step $isManual $isPrompt $description

#$isManual='false'
#$step=$step+1
#$command="set-Location  $microServiceDir/$($kubeDockerFileDir[$i])"
#excec-Command $command $step $isManual $isPrompt

set-Location  $microServiceDir/$($kubeDockerFileDir[$i])

$isManual='false'
$step=$step+1
$description = "Build new Docker image to reflect new update."
$command="docker build -t $($kubeName[$i]):$tag ."
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Tag Docker image with new version."
$command="docker tag $($kubeName[$i]):$tag $acrName.azurecr.io/repo/$($kubeName[$i]):$tag"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Push Docker image to Azure ACR."
$command="docker push $acrName.azurecr.io/repo/$($kubeName[$i]):$tag"
excec-Command $command $step $isManual $isPrompt $description

$kubeTier="api"
  
$cpuRequest = "100m"
$cpuLimit = "1000m"
$changeCause = "Applied MSI with apiget and retreive connectionString from Keyvault."

set-DeploymentMSIKv $acrName $tempDir $($kubeName[$i]) $kubeTier $($kubePort[$i]) $tag $cpuRequest $cpuLimit $changeCause $identitySelector

$isManual='false'
$step=$step+1
$command="Review new manifest file of apiget. Observe aadpodidbinding:, this associate to AAD pod identity.
          Therefore, new apiget pod can access keyvault with MSI service through pod identity."
$command="cat $tempDir/deploy-$($kubeName[$i]).yaml"
excec-Command $command $step $isManual $isPrompt $command $description

$isManual='false'
$step=$step+1
$description = "Deploy new apiget with new manifest file."
$command="kubectl apply -f $tempDir/deploy-$($kubeName[$i]).yaml "
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Verify that website can still access Azure MySQL Service by apiget  "
$command=" access http://$frontFQDN and click Movies menu to test apiget."
excec-Command $command $step $isManual $isPrompt $description 

$isManual='true'
$step=$step+1
$description = "Congratulations!!! You have just completed the following:
                1. Mitigated attack surface (risk) by removing plain text of password from your code.
                2. Secured your password in Azure Keyvault.
                3. Accessed Azure Keyvault to get password with Managed Identity Service. 
                "
$command="..."
excec-Command $command $step $isManual $isPrompt $description

Set-Location $SectionRoot

# Podidentity with MSI to access direct to MySQL -----------------------------
<#
$i = 0
$tag = "v5.0"

$isManual='false'
$step=$step+1
$command="az ad user show --id $emailWorkshop --query objectId -o tsv"
$aadObjectID = excec-Command-ReturnV $command $step $isManual $isPrompt
$aadObjectID = [string]::join("",($aadObjectID.Split("`n")))

$isManual='true'
$step=$step+1
$command="Object ID of $emailWorkshop`: $aadObjectID"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="az mysql server ad-admin create --server-name 'mysqlxx$suffix' -g $resourceGroupName --display-name $emailWorkshop --object-id $aadObjectID"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="az account get-access-token --resource-type oss-rdbms --output tsv --query accessToken"
$accessToken = excec-Command-ReturnV $command $step $isManual $isPrompt
$accessToken = [string]::join("",($accessToken.Split("`n")))

$isManual='true'
$step=$step+1
$command="MySQL access token`: $accessToken"
excec-Command $command $step $isManual $isPrompt

$aks = az aks show -g $resourceGroupName -n $aksName | ConvertFrom-Json
$nodeResourceGroupName = $aks.nodeResourceGroup

$isManual='false'
$step=$step+1
$command="az identity list -g $nodeResourceGroupName --query ""[?contains(name, 'agentpool')]""  | ConvertFrom-Json"
$MSIid = excec-Command-ReturnV $command $step $isManual $isPrompt

$IDClientID = $MSIid.clientId
$IDClientID = [string]::join("",($IDClientID.Split("`n")))

$isManual='true'
$step=$step+1
$command="Managed Identity`: $IDClientID"
excec-Command $command $step $isManual $isPrompt


#$isManual='false'
#$step=$step+1
#$command="mysql --user $emailWorkshop@mysqlxx$suffix -h mysqlxx$suffix.mysql.database.azure.com --enable-cleartext-plugin --password=$accessToken"
#excec-Command $command $step $isManual $isPrompt


#DROP user 'myuser';

$isManual='false'
$step=$step+1
$command="mysql --user $emailWorkshop@mysqlxx$suffix -h mysqlxx$suffix.mysql.database.azure.com --enable-cleartext-plugin --password=$accessToken -e 'DROP user ''myuser'';'"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="mysql --user $emailWorkshop@mysqlxx$suffix -h mysqlxx$suffix.mysql.database.azure.com --enable-cleartext-plugin --password=$accessToken -e 'SET aad_auth_validate_oids_in_tenant = OFF;CREATE AADUSER ''myuser'' IDENTIFIED BY ''$IDClientID'';'"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="mysql --user $emailWorkshop@mysqlxx$suffix -h mysqlxx$suffix.mysql.database.azure.com --enable-cleartext-plugin --password=$accessToken -e 'GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, PROCESS, REFERENCES, INDEX, ALTER, SHOW DATABASES, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, REPLICATION SLAVE, REPLICATION CLIENT, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, CREATE USER, EVENT, TRIGGER ON *.* TO ''myuser''@''%'' WITH GRANT OPTION;'"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="mysql --user $emailWorkshop@mysqlxx$suffix -h mysqlxx$suffix.mysql.database.azure.com --enable-cleartext-plugin --password=$accessToken -e 'FLUSH PRIVILEGES;'"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="cat $microServiceDir/moviesAPI_get/Startup.cs"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="Copy-Item $microServiceDir/tempCodes/Startup.cs_msi  -Destination $microServiceDir/moviesAPI_get/Startup.cs"
excec-Command $command $step $isManual $isPrompt

$i = 0
$tag = "v12.0"

$isManual='false'
$step=$step+1
$command="cat $microServiceDir/moviesAPI_get/Startup.cs"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="cat $microServiceDir/moviesAPI_get/appsettings.json"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="Copy-Item $microServiceDir/tempCodes/appsettings.json_noConnectionString  -Destination $microServiceDir/moviesAPI_get/appsettings.json"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="cat $microServiceDir/moviesAPI_get/appsettings.json"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="set-Location  $microServiceDir/$($kubeDockerFileDir[$i])"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="docker build -t $($kubeName[$i]):$tag ."
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="docker tag $($kubeName[$i]):$tag $acrName.azurecr.io/repo/$($kubeName[$i]):$tag"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="docker push $acrName.azurecr.io/repo/$($kubeName[$i]):$tag"
excec-Command $command $step $isManual $isPrompt

$kubeTier="api"
  
$cpuRequest = "100m"
$cpuLimit = "1000m"
$changeCause = "Applied MSI with apiget and access to MySQL PaaS directly."

set-DeploymentMSIKv $acrName $tempDir $($kubeName[$i]) $kubeTier $($kubePort[$i]) $tag $cpuRequest $cpuLimit $changeCause $identitySelector

$isManual='false'
$step=$step+1
$command="cat $tempDir/deploy-$($kubeName[$i]).yaml"
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="kubectl delete -f $tempDir/deploy-$($kubeName[$i]).yaml "
excec-Command $command $step $isManual $isPrompt

$isManual='false'
$step=$step+1
$command="kubectl apply -f $tempDir/deploy-$($kubeName[$i]).yaml "
excec-Command $command $step $isManual $isPrompt

$isManual='true'
$step=$step+1
$command="Access http://$frontFQDN and click Movies menu to test apiget."
excec-Command $command $step $isManual $isPrompt



<#
SET aad_auth_validate_oids_in_tenant = OFF;
CREATE AADUSER 'myuser' IDENTIFIED BY 'cc5e6297-6bdc-4608-9ab5-ddb0c81e2a7e';
--I would also recommend to GRANTS necessary permission in DB
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, PROCESS, REFERENCES, INDEX, ALTER, SHOW DATABASES, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, REPLICATION SLAVE, REPLICATION CLIENT, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, CREATE USER, EVENT, TRIGGER ON *.* TO 'myuser'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
#>
<#
$identity=$null
while($identity -eq $null) {
echo "Retrying until Identity is ready..."
$identity = az identity list -g $aks.nodeResourceGroup --query "[?contains(name, 'agentpool')]"  | ConvertFrom-Json                                        
}

$IDPrinID = $identity.principalId
$kvID = $keyVault.id

$IDClientID = $identity.clientId


az mysql server ad-admin create --server-name testsvr -g testgroup --display-name username@domain.com --object-id $aadObjectID"
# Get resource ID of the user-assigned identity
#resourceID=$(az identity show --resource-group myResourceGroup --name myManagedIdentity --query id --output tsv)

# Get client ID of the user-assigned identity
$aadObjectID = az ad user show --id $emailWorkshop --query objectId -o tsv

$command="az mysql server ad-admin create --server-name 'mysqlxx$suffix' -g $resourceGroupName --display-name $emailWorkshop --object-id 1FCD6583-267B-4484-BF9B-507E4B62DE79

"
excec-Command $command $step $isManual $isPrompt


az mysql server ad-admin create --server-name testsvr -g testgroup --display-name username@domain.com --object-id 1FCD6583-267B-4484-BF9B-507E4B62DE79

#>



