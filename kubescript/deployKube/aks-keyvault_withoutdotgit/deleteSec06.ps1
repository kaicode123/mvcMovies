Write-output "Deleting All Provisioned Resources by section02.ps1... " "`n" 

. /workspace/SimpleDotnetMysql/kubescript/deployKube/aks-keyvault_withoutdotgit/initParameters.ps1


$OrgSuffixName

Read-host "Delete the organization named $OrgSuffixName and then increase $incremental"
rm -r /workspace/frontend/

#$projectId = az devops project list --organization https://dev.azure.com/$OrgSuffixName --query "value[?contains(name,'mvcmovies')].id"  -o tsv

 #az devops project delete --id e2ef83f3-6ae9-4291-93fb-1cefae887a3b  --organization https://dev.azure.com/devopsorgb1