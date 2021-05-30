Write-output "Welcome to LAB Section#2 Explore AKS features" "`n" 

. /workspace/SimpleDotnetMysql/kubescript/deployKube/aks-keyvault_withoutdotgit/initParameters.ps1
az acr login -n $acrName

<#
# https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=preview-page

$isManual='true'
$step=$step+1
$command="Please access https://dev.azure.com/ and create PAT token."
excec-Command $command $step $isManual $isPrompt

$PAT = Read-Host -Prompt "Please enter your PAT token"

$isManual='true'
$step=$step+1
$command="`$AZURE_DEVOPS_EXT_PAT = $PAT"
excec-Command $command $step $isManual $isPrompt

$AZURE_DEVOPS_EXT_PAT =  $PAT

$isManual='false'
$step=$step+1
$command="az devops login"
excec-Command $command $step $isManual $isPrompt
#>


#--- Create Organization manual step.
$rand = Get-Random -Maximum 100
$OrgSuffixName = "devopsorg$suffix$rand"

$isManual='true'
$step=$step+1
$description = "Create your Azure DevOps Organization."
$command=" 1. Access https://dev.azure.com/
           2. Follow the instruction from https://akslabinstruction.blob.core.windows.net/vdocontainer/Setup_DevOps_Organization.mp4
           3. Input organization name as $OrgSuffixName"
excec-Command $command $step $isManual $isPrompt $description

#$OrgSuffixName = read-host "Please enter organization name"
#$OrgSuffixName = "devopsorgb1"
$OrgName = "https://dev.azure.com/$OrgSuffixName"


$isManual='false'
$step=$step+1
$description = "Create Azure DevOps Project in your Organization."
$command="az devops project create --name mvcmovies --org $OrgName"
excec-Command $command $step $isManual $isPrompt $description

az devops team create --name team1 --project mvcmovies  --org $OrgName

$isManual='false'
$step=$step+1
$description = "Create Azure Repository in your project."
$command="az repos create --name frontend  --project mvcmovies  --org $OrgName"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Get username and password of Azure Repository."
$command="Open $OrgName and then:
          follow the instruction from: https://akslabinstruction.blob.core.windows.net/vdocontainer/Get_Repos_credential.mp4"
excec-Command $command $step $isManual $isPrompt $description

#$isManual='false'
#$step=$step+1
#$command="Set-Location /workspace"
#excec-Command $command $step $isManual $isPrompt

Set-Location /workspace

$isManual='false'
$step=$step+1
$description = "Clone the empty Azure reposity to your working machine."
$command="git clone $OrgName/mvcmovies/_git/frontend"
excec-Command $command $step $isManual $isPrompt $description 

#$isManual='false'
#$step=$step+1
#$command="git config --global credential.helper 'cache --timeout=9000'"
#excec-Command $command $step $isManual $isPrompt

git config --global credential.helper 'cache --timeout=9000'



$isManual='false'
$step=$step+1
$description = "Copy all codes of frontend to repository."
$command="cp -r /workspace/SimpleDotnetMysql/MvcMovieMicroService/MvcMovie/* /workspace/frontend"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Create service connection from DevOps to ACR. This to allow DevOps to access Docker images in ACR.
                *** You may need to unblock web popup as we need to login again."
$command="Open $OrgName and then:
          follow the instruction from: https://akslabinstruction.blob.core.windows.net/vdocontainer/Setup_SP_for_ACR.mp4"

excec-Command $command $step $isManual $isPrompt $description

sleep 5

$ServiceConnectionID = az devops service-endpoint list  --project mvcmovies --org $OrgName  --query "[?contains(name,'ACRConnect')].id"  -o tsv
echo "ServiceConnectionID is $ServiceConnectionID"
set-BuildPipeline $acrName $ServiceConnectionID

$isManual='false'
$step=$step+1
$description = "Review Build pipeline manifest file. This will be used to create build pipeline."
$command="cat /workspace/frontend/pipeline-build.yaml"
excec-Command $command $step $isManual $isPrompt $description

#$isManual='false'
#$step=$step+1
#$command="Set-Location /workspace/frontend"
#excec-Command $command $step $isManual $isPrompt

Set-Location /workspace/frontend

$isManual='false'
$step=$step+1
$description = "Add all code files and build pipeline manifest file into Azure local repository."
$command="git add -A"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Commit change to local repository."
$command="git commit -m ""***NO_CI***"""
excec-Command $command $step $isManual $isPrompt $description 

$isManual='false'
$step=$step+1
$description = "Push (upload) all source codes to remote repository (Azure)."
$command="git push"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Create build pipeline."
$command="az pipelines create --name 'frontendBuild' --description 'Build pipeline for frontend'--repository $OrgName/mvcmovies/_git/frontend --branch master --yml-path pipeline-build.yaml --project mvcmovies  --org $OrgName  --skip-first-run"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Verify new pipeline in Azure DevOps Project."
$command="Open $OrgName and verify new pipeline."
excec-Command $command $step $isManual $isPrompt $description

set-Deployment-Frontend-CD $acrName

$isManual='false'
$step=$step+1
$description = "Review new manifest file of frontend deployment. Observe Build.BuildNumber. 
                We let the version of deployment running by build number generated by build pipeline."
$command="cat /workspace/frontend/deploy-mvcmoviefrontend.yaml"
excec-Command $command $step $isManual $isPrompt $description

#$isManual='false'
#$step=$step+1
#$command="Set-Location /workspace/frontend"
#excec-Command $command $step $isManual $isPrompt

Set-Location /workspace/frontend

$isManual='false'
$step=$step+1
$description = "Add new manifest file to local repository."
$command="git add -A"
excec-Command $command $step $isManual $isPrompt $description 

$isManual='false'
$step=$step+1
$description = "Commit change to local repository."
$command="git commit -m ""added deploy-mvcmoviefrontend.yaml"""
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Push (upload) change to remote repository (Azure)."
$command="git push"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Build process is now triggered."
$command="Observe build pipeline progress."
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Setup release pipeline."
$command="Open $OrgName and then:
          follow the instruction from: https://akslabinstruction.blob.core.windows.net/vdocontainer/Setup_Realease_Pipeline.mp4"
excec-Command $command $step $isManual $isPrompt $description



$GreetingMessage = "Built by Azure Pipeline!!!"
set-homeFrontendCD  $suffix $GreetingMessage

$isManual='false'
$step=$step+1
$description = "Modify greeting message on home page."
$command="cat /workspace/frontend/Views/Home/Index.cshtml"
excec-Command $command $step $isManual $isPrompt $description

#$isManual='false'
#$step=$step+1
#$description = "Modify greeting message on home page."
#$command="Set-Location /workspace/frontend"
#excec-Command $command $step $isManual $isPrompt $description

Set-Location /workspace/frontend

$isManual='false'
$step=$step+1
$description = "Add source change to local repository."
$command="git add -A"
excec-Command $command $step $isManual $isPrompt $description

$isManual='false'
$step=$step+1
$description = "Commit change to local repository."
$command="git commit -m ""Fixed greeting message."""
excec-Command $command $step $isManual $isPrompt $description 

$isManual='false'
$step=$step+1
$description = "Push (upload) change to remote repository (Azure)."
$command="git push"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Verify automated build and release pipeline with deployment approval."
$command="Open $OrgName and then:
          follow the instruction from: https://akslabinstruction.blob.core.windows.net/vdocontainer/Observe_build_and_release_pipeline.mp4"
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Verify new greeting message on home page."
$command="Access web: http://$frontFQDN and verify greeting message."
excec-Command $command $step $isManual $isPrompt $description

$isManual='true'
$step=$step+1
$description = "Congratulations!!! You have just completed the following:
                1. Created new DevOps Organization with project and Repository.
                2. Created build pipeline to build whenever the developer push change to repo. 
                   The source code was built as Docker images file and push to ACR.
                3. Created release pipeline to pull the image from ACR and deploy to AKS with an approval.
                "
$command="..."
excec-Command $command $step $isManual $isPrompt $description

Set-Location $SectionRoot



