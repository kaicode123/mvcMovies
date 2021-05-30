Write-output "Welcome to LAB Section#2 Secure in-transit traffic with TLS (https) and Azure Active Directory integration." "`n" 

. /workspace/SimpleDotnetMysql/kubescript/deployKube/aks-keyvault_withoutdotgit/initParameters.ps1
az acr login -n $acrName


$isPrompt = 'true'
$isManual = "false"

# --- Create Simple Ingress (without TLS)
# --- Delete Load Balancer
$isManual='false'
$step=$step+1
$description = "Remove existing Load Balancer that currently pointed to frontend."
$command="kubectl delete service/mvcmoviefrontend$suffix"
excec-Command $command $step $isManual $isPrompt $description 

$isManual='false'
$step=$step+1
$description = "Remove A record pointed to load balancer."
$command="az network dns record-set a delete --name $websiteName --resource-group $resourceGroupName --zone-name $domainName --yes"
excec-Command $command $step $isManual $isPrompt

$serviceName = "mvcmoviefrontend"
$tier = "frontend"
$port = "80"
$type = "ClusterIP"
set-Service $tempDir $serviceName $tier $port $type $suffix $frontendServiceName

$isManual='false'
$step=$step+1
$description = "Review ClusterIP service to point to frontend. We will create Ingress (nginx) to point to ClusterIP soon."
$command="cat $tempDir/service-mvcmoviefrontend.yaml"
excec-Command $command $step $isManual $isPrompt $description $description

$isManual='false'
$step=$step+1
$description = "Create ClusterIP service"
$command="kubectl create -f $tempDir/service-mvcmoviefrontend.yaml"
excec-Command $command $step $isManual $isPrompt $description 

$isManual='false'
$step=$step+1
$description = "Add helm repo for nginx."
$command="helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx"
excec-Command $command $step $isManual $isPrompt $description

#$isManual='false'
#$step=$step+1
#$command="helm repo add stable https://kubernetes-charts.storage.googleapis.com/"
#excec-Command $command $step $isManual $isPrompt

helm repo add stable https://kubernetes-charts.storage.googleapis.com/

$isManual='false'
$step=$step+1
$description = "Update helm repo. (that has just been added.)"
$command="helm repo update"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$description = "Insall nginx as Ingress"
$command="helm install ingress ingress-nginx/ingress-nginx"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Verify that nginx has been installed by helm."
$command="helm list"
excec-Command $command $step $isManual $isPrompt $description


# ---- Set ingress 
$port="80"
$serviceName = "mvcmoviefrontend"
set-Ingress $tempDir $serviceName $port $suffix

$isManual='false'
$step=$step+1
$description = "Now configure nginx. Observe backend: this points to ClusterIP service."
$command="cat $tempDir/ingress-$serviceName.yaml"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Deploy nginx configuration and next we will loop until nginx gets Public IP Address."
$command="kubectl apply -f  $tempDir/ingress-$serviceName.yaml  --validate=false"
#excec-Command $command $step $isManual $isPrompt $description

$isOK = 'false'
#$isPrompt = 'false'
while ($isOK -ne 'ingress.extensions/igfrontend80 created'){
$isOK = excec-Command-ReturnV $command $step $isManual $isPrompt
$isOK = [string]::join("",($isOK.Split("`n")))
write-host "$isOK"
sleep 10
}
#$isPrompt = 'true'

$ingressIP = "80"
while ($ingressIP -eq "80"){
    sleep 5
    $arrayString = kubectl get ingress  |  Select-String -Pattern igfrontend
    $arrayString = $arrayString -split '\s+'
    $ingressIP = $arrayString[3]

    $command="kubectl get ingress igfrontend80"
    excec-Command $command 'xxx' $isManual 'false'
}



$isManual='false'
$step=$step+1
$description = "Create new DNS A record object for Public IP from nginx"
$command="az network dns record-set a create --name $websiteName --resource-group $resourceGroupName --ttl 10 --zone-name $domainName --output table"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Associate DNS A record to Public IP from nginx."
$command="az network dns record-set a add-record -g $resourceGroupName -z $domainName -n $websiteName -a $ingressIP --ttl 10 --output table"
excec-Command $command $step $isManual $isPrompt $description

sleep 10

$isManual='true'
$step=$step+1
$description = "Verify that we still access to website via new ingress (nginx)."
$command="Access http://$frontFQDN"
excec-Command $command $step $isManual $isPrompt $description

# -- CertManager 

$isManual='false'
$step=$step+1
$description = "Let's secure in-transit traffic with https. First remove existing plain http ingress."
$command="kubectl delete ingress igfrontend80"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Install Cert Manager. This is for SSL certificate life cycle management."
$command="kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.0.2/cert-manager.yaml"
excec-Command $command $step $isManual $isPrompt $description

#while ('true'){
#kubectl get all -n cert-manager
#sleep 3
#}

#$name = "letsencrypt-prod"
#$server = "https://acme-v02.api.letsencrypt.org/directory"
#$key = "letsencrypt-prod"


$issuerName = "letsencrypt-staging"
$server = "https://acme-staging-v02.api.letsencrypt.org/directory"
$key = "letsencrypt-staging"

set-Issuer $emailWorkshop $tempDir $issuerName $server $key
$isManual='false'
$step=$step+1
$description = "Set certificate issuer to letsencrypt. 
                This is a free yet powerfull SSL Certificate provider.
                For the first step, we deploy issuer for staging state for testing."
$command="cat $tempDir/issuer.yaml"
excec-Command $command $step $isManual $isPrompt $description


$isManual='false'
$step=$step+1
$description = "Deploy staging issuer and then loop until the issuer is ready."
$command="kubectl create -f  $tempDir/issuer.yaml  --validate=false"
#$isOK = 'false'
while ($isOK -ne "issuer.cert-manager.io/$issuerName created"){
$isOK = excec-Command-ReturnV $command $step $isManual $isPrompt
$isOK = [string]::join("",($isOK.Split("`n")))
#write-host "$isOK"
sleep 5
}

$isIssuerReady = "null"

while ($isIssuerReady -ne "True"){
    sleep 5
    $arrayString =  kubectl get issuer | Select-String -Pattern "$issuerName"
    $arrayString = $arrayString -split '\s+'
    $isIssuerReady = $arrayString[1]

    $command="kubectl get issuer"
    excec-Command $command 'xxx' $isManual 'false'
}

#$isManual='false'
#$step=$step+1
#$command="kubectl get issuer"
#excec-Command $command $step $isManual $isPrompt

$port="80"
$serviceName = "mvcmoviefrontend"
$secretName = "tls-staging"
set-IngressTLS $tempDir $serviceName $port $websiteName $issuerName $secretName $domainName
$isManual='false'
$step=$step+1
$description = "Review new nginx ingress with TLS certificate configured. (still in staging)"
$command="cat $tempDir/ingress-$serviceName.yaml"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Aplly ingress with TLS certificate staging configured."
$command="kubectl apply -f  $tempDir/ingress-$serviceName.yaml  --validate=false"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Verify that nginx with TLS certificate statging is deployed and then loop to see whether certificate is ready."
$command="kubectl get ingress igfrontend443"
excec-Command $command $step $isManual $isPrompt $description

### - TO Do - wait until ingress frontend get IP


$getCert = "null"

while ($getCert -ne "True"){

    sleep 5
    $arrayString = kubectl get certificate | Select-String -Pattern "tls-staging"
    $arrayString = $arrayString -split '\s+'
    $getCert = $arrayString[1]

    $command="kubectl get certificate"
    excec-Command $command 'xxx' $isManual 'false'
    
}

$isManual='true'
$step=$step+1
$description = "Verify that certifcate has been applied to website. 
                However it is invalid as this is fake cert. for staging (test) purpose."
$command="Access https://$frontFQDN and verify certificate."
excec-Command $command $step $isManual $isPrompt $description
$isManual = "false"

# Switch to cert-prod ---------------------------------------------------------



$issuerName = "letsencrypt-prod"
$server = "https://acme-v02.api.letsencrypt.org/directory"
$key = "letsencrypt-prod"


set-Issuer $emailWorkshop $tempDir $issuerName $server $key
$step=$step+1
$description = "Now we are ready for production certificate. Change issuer to to production."
$command="cat $tempDir/issuer.yaml"
excec-Command $command $step $isManual $isPrompt $description

$step=$step+1
$description = "Deploy production issuer and then loop until the issuer is ready."
$command="kubectl create -f  $tempDir/issuer.yaml  --validate=false"
$isOK = 'false'
while ($isOK -ne "issuer.cert-manager.io/$issuerName created"){
    $isOK = excec-Command-ReturnV $command $step $isManual $isPrompt 
    $isOK = [string]::join("",($isOK.Split("`n")))
    write-host "$isOK"
    sleep 5
}

$isIssuerReady = "null"

while ($isIssuerReady -ne "True"){
    sleep 5
    $arrayString =  kubectl get issuer | Select-String -Pattern "$issuerName"
    $arrayString = $arrayString -split '\s+'
    $isIssuerReady = $arrayString[1]

    $command="kubectl get issuer"
    excec-Command $command 'xxx' $isManual 'false'
}

#$isManual='false'
#$step=$step+1
#$command="kubectl get issuer"
#excec-Command $command $step $isManual $isPrompt

$port="80"
$serviceName = "mvcmoviefrontend"
$secretName = "tls-prod"
set-IngressTLS $tempDir $serviceName $port $websiteName $issuerName $secretName $domainName

$step=$step+1
$description = "Review new nginx ingress with TLS certificate configured. (Note this is the  production.)"
$command="cat $tempDir/ingress-$serviceName.yaml"
excec-Command $command $step $isManual $isPrompt $description

$step=$step+1
$description = "Apply new ingress."
$command="kubectl apply -f  $tempDir/ingress-$serviceName.yaml  --validate=false"
excec-Command $command $step $isManual $isPrompt $description 

$step=$step+1
$description = "Verify that new ingress nginx is ready and then loop to see whether production certificate is ready."
$command="kubectl get ingress igfrontend443"
excec-Command $command $step $isManual $isPrompt $description

$getCert = "null"

while ($getCert -ne "True"){

    sleep 5
    $arrayString = kubectl get certificate | Select-String -Pattern "tls-prod"
    $arrayString = $arrayString -split '\s+'
    $getCert = $arrayString[1]

    $command="kubectl get certificate"
    excec-Command $command 'xxx' $isManual 'false'
    
}

$isManual='true'
$step=$step+1
$description = "Verify that we can access website with valid SSL certificate."
$command="Access web: https://$frontFQDN and verify the validation of certificate.'"
excec-Command $command $step $isManual $isPrompt $description
$isManual = "false"


# AAD Authenticate ----------------------------------------------------------
# https://cann0nf0dder.wordpress.com/2020/06/24/grant-application-and-delegate-permissions-using-an-app-registration/


$serviceName = "mvcmoviefrontend"
$step=$step+1
$description = "Now we will ingreate our website to Azure Active Directory for user authentication. First, delete existing ingress (TLS nginx)."
$command="kubectl delete -f $tempDir/ingress-$serviceName.yaml"
excec-Command $command $step $isManual $isPrompt $description 

$step=$step+1
$description = "Create app registration. This app will be used for oauth2 proxy."
$command="az ad app create --display-name oauthApp$suffix --available-to-other-tenants false --reply-urls  https://$frontFQDN/oauth2/callback  --password $appPassword  --credential-description forOauth |  convertfrom-json"
$oauthApp= excec-Command-ReturnV $command $step $isManual $isPrompt $description 


$isPrompt = 'true'
$isManual = 'ture'
$step=$step+1
$description = "In order to allow oauth2 proxy integrate with AAD, it needs User.Read Graph permission for associated app."
$command="Open Azure Portal, go to AAD, select created app [oauthApp$suffix] and go API Permission then add Graph delegated type of User.Read permission to Application. "
excec-Command $command $step $isManual $isPrompt $description

$oauthAppID = $oauthApp.appId


$isManual = 'true'
$step=$step+1
$description = "Review Application ID, this will be associated to oauth2 proxy."
$command="Application ID is : $oauthAppID"
excec-Command $command $step $isManual $isPrompt $description

$isManual = 'true'
$step=$step+1
$description = "Review Tenant ID, this will be associated to oauth2 proxy."
$command="Tenant ID is : $tenantId"
excec-Command $command $step $isManual $isPrompt $description

$isManual = 'true'
$step=$step+1
$description = "Review Secret, this will be associated to oauth2 proxy."
$command="Secert is : BJ~__2o-BzI06fXutaxiZ3HnQLAol-YwV-"
excec-Command $command $step $isManual $isPrompt $description



$deployName = "oauth2"
set-DeploymentOauth $tempDir $deployName $tenantId $appPassword $frontFQDN $oauthAppID

$deployName = "oauth2"
$isManual = 'false'
$step=$step+1
$description = "Now we will deploy oauth2 proxy. Review manifest file of oauth2 proxy.
                See the parameter that we associate to application registration."
$command="cat $tempDir/deploy-$deployName.yaml"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Deply oauth2 proxy."
$command="kubectl apply -f $tempDir/deploy-$deployName.yaml"
excec-Command $command $step $isManual $isPrompt $description

sleep 10 # --- to change to be better dectection.

$serviceName = "oauth2"
set-ServiceOauth $tempDir  $serviceName

$step=$step+1
$description = "Review manifest file (ClusterIP) for service of oauth2 proxy."
$command="cat $tempDir/service-$serviceName.yaml"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Deploy service for oauth2 proxy."
$command="kubectl apply -f $tempDir/service-$serviceName.yaml"
excec-Command $command $step $isManual $isPrompt $description

$serviceName = "oauth2Proxy"
$issuerName = "letsencrypt-prod"
$secretName = "tls-prod"
set-IngressOauthProxy $tempDir $serviceName $frontFQDN $issuerName $secretName

$step=$step+1
$description = "Review ingress (nginx) for oauth2 proxy."
                
$command="cat $tempDir/ingress-$serviceName.yaml"
excec-Command $command $step $isManual $isPrompt $description 

$isManual='false'
$step=$step+1
$description = "Deploy ingress (nginx) for oauth2 proxy and then loop to check whether production certificate is ready."
$command="kubectl apply -f $tempDir/ingress-$serviceName.yaml"
excec-Command $command $step $isManual $isPrompt $description

$getCert = "null"

while ($getCert -ne "True"){

    sleep 5
    $arrayString = kubectl get certificate | Select-String -Pattern "tls-prod"
    $arrayString = $arrayString -split '\s+'
    $getCert = $arrayString[1]

    $command="kubectl get certificate"
    excec-Command $command 'xxx' $isManual 'false'
}


$serviceName = "FrontendOauth2Proxy"
$issuerName = "letsencrypt-prod"
set-IngressFrontendOauth $tempDir $serviceName $frontFQDN $issuerName

$step=$step+1
$description = "Deploy new ingress for frontend for website. 
                Observe annotationns: The frontend ingress will redirect unauthenticated traffic to oauth2Proxy.
                Then oauth2Proxy will redirect to AAD for authentication."
$command="cat $tempDir/ingress-$serviceName.yaml"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Apply frontend Ingress."
$command="kubectl apply -f $tempDir/ingress-$serviceName.yaml"
excec-Command $command $step $isManual $isPrompt $description

$arrayString = kubectl get pods | Select-String -Pattern nginx 
$NginxName= $arrayString[0]

$command = "kubectl exec -it $NginxName -- sed -i 's/proxy_buffering                         off/proxy_buffering                         on/g' nginx.conf"
Invoke-Expression  $command
$command ="kubectl exec -it $NginxName -- sed -i 's/proxy_buffer_size                       4k/proxy_buffer_size                       128k/g' nginx.conf"
Invoke-Expression  $command
$command ="kubectl exec -it $NginxName -- sed -i 's/proxy_buffers                           4 4k/proxy_buffers                           4 128k/g' nginx.conf"
Invoke-Expression  $command
$command ="kubectl exec -it $NginxName -- nginx -s reload"
Invoke-Expression  $command

$isManual='true'
$step=$step+1
$description = "Access website and you will find that the authentication is required."
$command="Access web: https://$frontFQDN then autheticate with your AAD account.'"
excec-Command $command $step $isManual $isPrompt $description 

#-------------------------------
<#
$oauthAppID = $oauthApp.appId

$step=$step+1
$command="az ad sp create --id $oauthAppID | convertfrom-json "
$oauthSp = excec-Command-ReturnV $command $step $isManual $isPrompt

$oauthSpID = $oauthSp.appId
$oauth2PermissionsId = $oauthSp.oauth2Permissions.id

$delegatePermInfo = az ad sp show --id 00000003-0000-0000-c000-000000000000 --query "oauth2Permissions[?value=='Directory.ReadWrite.All']" | ConvertFrom-Json

$delegatePermInfoId = $delegatePermInfo.id

$step=$step+1
$command="az ad app permission add --id $oauthAppID  --api 00000003-0000-0000-c000-000000000000 --api-permissions 311a71cc-e848-46a1-bdf8-97ff7156d8e6=Scope"
excec-Command $command $step $isManual $isPrompt
 az ad app permission grant --id 8ee21a44-df0c-4b38-ab83-03ac336318c3 --api 00000003-0000-0000-c000-000000000000 --scope user.read --debug

$step=$step+1
$command="az ad app permission grant --id $oauthAppID --api 00000003-0000-0000-c000-000000000000 --scope  user.read --consent-type AllPrincipals"
excec-Command $command $step $isManual $isPrompt

$oauthSpID = $oauthSp.appId
$oauth2PermissionsId = $oauthSp.oauth2Permissions.id



$step=$step+1
#$command="az ad app permission add --id $oauthAppID --api 00000003-0000-0000-c000-000000000000 --api-permissions User.Read=Scope
#$command="az ad app permission add --id $oauthAppID --api 00000003-0000-0000-c000-000000000000 --api-permissions $oauth2PermissionsId=Scope"
#$oauthApp= excec-Command-ReturnV $command $step $isManual $isPrompt
#Scope is delegated permision

#$step=$step+1
#$command="az ad app permission grant --id $oauthAppID --api 00000003-0000-0000-c000-000000000000 --scope user_impersonation --consent-type AllPrincipals"
#excec-Command $command $step $isManual $isPrompt



#az ad app permission grant --id e042ec79-34cd-498f-9d9f-1234234 --api a0322f79-57df-498f-9d9f-12678


#>