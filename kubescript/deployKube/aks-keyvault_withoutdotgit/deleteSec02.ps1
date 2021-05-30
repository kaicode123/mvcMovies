Write-output "Deleting All Provisioned Resources by section02.ps1... " "`n" 

. /workspace/SimpleDotnetMysql/kubescript/deployKube/aks-keyvault_withoutdotgit/initParameters.ps1

kubectl delete service/mvcmoviefrontend
kubectl delete ingress igfrontend80
helm uninstall ingress
az network dns record-set a delete --name $websiteName --resource-group $resourceGroupName --zone-name $domainName --yes

kubectl delete  -f https://github.com/jetstack/cert-manager/releases/download/v1.0.2/cert-manager.yaml

#--- Delete namespace
$NAMESPACE="cert-manager"
kubectl get namespace $NAMESPACE -o json > $NAMESPACE.json
sed -i -e 's/"kubernetes"//' $NAMESPACE.json
kubectl replace --raw "/api/v1/namespaces/$NAMESPACE/finalize" -f ./$NAMESPACE.json




kubectl delete issuer letsencrypt-prod letsencrypt-staging
kubectl delete ingress ssl-frontend-ingress
kubectl delete ingress igfrontend443 frontend-oauth2-ingress oauth2-proxy-ingress

kubectl delete service oauth2-proxy

kubectl delete deployment oauth2-proxy


$appId= az ad app list  --filter "displayName eq 'oauthApp$suffix'" --query [].appId -o tsv
az ad app delete --id $appId

# kubectl delete secret ingress-ingress-nginx-admission letsencrypt-staging

