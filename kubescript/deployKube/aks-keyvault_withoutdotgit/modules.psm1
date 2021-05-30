function set-Appsettings ($suffix, $microServiceDir, $api, $port  ) {
##param([string]$suffix , [string]$microServiceDir , [string]$api , [string]$port) 

 Set-Content  -Path "$microServiceDir/$api/appsettings.json" -Value "
{
  ""Logging"": {
    ""LogLevel"": {
      ""Default"": ""Information"",
      ""Microsoft"": ""Warning"",
      ""Microsoft.Hosting.Lifetime"": ""Information""
    }
  },
  ""AllowedHosts"": ""*"",
  ""ConnectionStrings"": {
    ""MvcMovieContext"": ""Server=mysqlxx$suffix.mysql.database.azure.com; Port=3306; Database=movies; Uid=mysqladmin$suffix@mysqlxx$suffix; Pwd=1Q2w3e4r5t6y; SslMode=Preferred;""
  },
  ""urls"": ""http://0.0.0.0:$port""
}
"
}
#------------------------------------------------------------------------------------
function set-Deployment ($acrName, $tempDir, $deployName, $tier, $port, $tag, $cpuRequest, $cpuLimit, $changeCause) {

Set-Content  -Path "$tempDir/deploy-$deployName.yaml" -Value "
apiVersion: apps/v1 #  for k8s versions before 1.9.0 use apps/v1beta2  and before 1.8.0 use extensions/v1beta1
kind: Deployment
metadata:
  name:  $deployName
  annotations:
    kubernetes.io/change-cause: $changeCause
spec:
  selector:
    matchLabels:
      app:   $deployName
      tier:  $tier
  replicas: 
  template:
    metadata:
      labels:
        app:  $deployName
        tier: $tier
    spec:
      containers:
      - name:  $deployName
        image: $acrName.azurecr.io/repo/$deployName`:$tag
        imagePullPolicy: Always
        resources:
          requests:
            cpu: $cpuRequest
            memory: 100Mi
          limits:
            cpu: $cpuLimit
        env:
        - name: GET_HOSTS_FROM
          value: dns
          # If your cluster config does not include a dns service, then to
          # instead access environment variables to find service host
          # info, comment out the 'value: dns' line above, and uncomment the
          # line below:
          # value: env
        ports:
        - containerPort: $port
"
}
#-----------------------------------------------------------------------------------------
function set-Service ($tempDir, $serviceName, $tier, $port, $type, $suffix, $frontendServiceName) {

$setDNS = ""
$setServiceName = ""

if ($type -eq "LoadBalancer"){

    $setDNS = "service.beta.kubernetes.io/azure-dns-label-name: $frontendServiceName"
    $setServiceName = $serviceName + $suffix
}

else {

    $setDNS = ""
    $setServiceName = $serviceName

}


Set-Content  -Path $tempDir"/service-$serviceName.yaml" -Value "
apiVersion: v1
kind: Service
metadata:
  labels:
    app:  $serviceName
    tier: $tier
  annotations:
    $setDNS
  name: $setServiceName
spec:
  ports:
  - port: $port
    protocol: TCP
    targetPort: $port
  selector:
    app: $serviceName
    tier: $tier
  type: $type
  "
 }

#------------------------------
<#
function set-DockerImage ($acrName, $microServiceDir, $imageName, $dockerFileDir, $tag) {
set-Location  "$microServiceDir/$dockerFileDir"
Write-output "Executing: docker build -t $imageName . " "`n"
docker build -t "$imageName:$tag" .
docker tag $imageName "$acrName.azurecr.io/repo/$imageName:$tag"
docker push $acrName".azurecr.io/repo/"$imageName
}
#>
#------------------------------
function excec-Command ($command, $step, $isManual, $isPrompt, $description){

$input = 'null'
$desSuffix = 'null'

if ($isManual -eq 'false')
{

$desSuffix = "Press 'g' to execute:"

} else {

$desSuffix = "[Manual step] press 'g' when done:"

}

Write-output  "`n[Step $step] $description"

    if ($isPrompt -eq 'true'){

        while ( $input -ne 'g'){
             $input=Read-Host -Prompt "$desSuffix $command"
             write-Host "`n"
           
         }
    }
    else{
       write-Host "Executing: $command `n"
    }


    if ($isManual -eq 'false'){
        #$return=Invoke-Expression $command
        Invoke-Expression $command
    }

}

#-------------------------------
function excec-Command-ReturnV ($command, $step, $isManual, $isPrompt, $description){

$input = 'null'
$return= 'null'

$desSuffix = 'null'

if ($isManual -eq 'false')
{

$desSuffix = "Press 'g' to execute:"

} else {

$desSuffix = "[Manual step] press 'g' when done:"

}

    
   if ($isPrompt -eq 'true'){     
        while ($input -ne 'g' ){
      
            $input=Read-Host -Prompt "$desSuffix $command"
            write-Host "`n"
        }
   }
   else{
       write-Host "`n[Step $step] Executing: $command `n"
    }
    

    if ($isManual -eq 'false'){

        $return = Invoke-Expression $command
    }

return $return

}

#-------------------------------
function set-mysqlImport ($suffix, $dbPassword, $tempDir ) {
##param([string]$suffix , [string]$microServiceDir , [string]$api , [string]$port) 
 Set-Content  -Path "$tempDir/mysqlImport" -Value "#!/bin/bash
mysql -umysqladmin$suffix@mysqlxx$suffix -p$dbPassword -h mysqlxx$suffix.mysql.database.azure.com < /workspace/SimpleDotnetMysql/kubescript/deployKube/mysql/movies.sql"
chmod 700 $tempDir/mysqlImport
}
#-------------------------------
function set-dmsJson ($scriptRoot, $direction, $dbPassword, $serverName, $userName ) {

Set-Content  -Path $scriptRoot"/mysql/json/$direction.json" -Value "
{
	""userName"": ""$userName"",
    ""password"": ""$dbPassword"",
	""serverName"": ""$serverName"",
	""databaseName"": ""movies"",
	""port"": 3306
}
"
}
#-------------------------------
function set-homeFrontend ($microServiceDir, $suffix, $GreetingMessage) {

Set-Content  -Path "$microServiceDir/MvcMovie/Views/Home/Index.cshtml" -Value "
@{
    ViewData[""Title""] = ""Home Page"";
}

<div class=""text-center"">
    <h1 class=""display-4"">$GreetingMessage</h1>
    <p>Learn about <a href=""https://docs.microsoft.com/aspnet/core"">building Web apps with ASP.NET Core</a>.</p>

    <img src=""https://storageaccountxx$suffix.blob.core.windows.net/aksblobcontainer$suffix/microsoft-azure-logo.jpg"" alt=""microsoft-azure-logo"">
</div>
"
}
#-----------------------------
function set-Ingress ($tempDir, $serviceName, $port, $suffix) {

#$setServiceName = $serviceName + $suffix

Set-Content  -Path "$tempDir/ingress-$serviceName.yaml" -Value "
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: igfrontend80
spec:
  rules:
  - http:
      paths:
      - path: /
        backend:
          serviceName: $serviceName
          servicePort: $port
"
}

#----------------------------------------------------------------------------------
function set-Issuer ($email,$tempDir,$name,$server,$key) {

Set-Content  -Path "$tempDir/issuer.yaml" -Value "
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: $name
spec:
  acme:
    server: $server
    email: $email
    privateKeySecretRef:
      name: $key
    solvers:
    - http01:
        ingress:
          class: nginx
"
}
#----------------------------------------------------------------------
function set-IngressTLS ($tempDir, $serviceName, $port, $websiteName, $issuerName, $secretName, $domainName) {

#$setServiceName = $serviceName + $suffix

Set-Content  -Path "$tempDir/ingress-$serviceName.yaml" -Value "
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: igfrontend443
  annotations:
    cert-manager.io/issuer: $issuerName
spec:
  tls:
  - hosts:
    - $websiteName.$domainName
    secretName: $secretName
  rules:
  - host: $websiteName.$domainName
    http:
      paths:
      - path: /
        backend:
          serviceName: mvcmoviefrontend
          servicePort: $port
"
}
#--------------------------------------------------------------------------------
function set-Hpa($tempDir, $serviceName) {

#$setServiceName = $serviceName + $suffix

Set-Content  -Path "$tempDir/hpa-$serviceName.yaml" -Value "
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: $serviceName
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: $serviceName
  minReplicas: 3
  maxReplicas: 100
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
"
}
# --- SSL Termination 

function set-Hpa2($tempDir, $serviceName) {

#$setServiceName = $serviceName + $suffix

Set-Content  -Path "$tempDir/hpa-$serviceName.yaml" -Value "
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: $serviceName
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: $serviceName
  minReplicas: 3
  maxReplicas: 100
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  behavior:
    scaleDown:
     stabilizationWindowSeconds: 60
     policies:
     - type: Percent
       value: 50
       periodSeconds: 5
    scaleUp:
     stabilizationWindowSeconds: 0
     policies:
     - type: Percent
       value: 50
       periodSeconds: 5
  "
}
# -----------------------------------------------------
function set-DeploymentRollingUpdate ($acrName, $tempDir, $deployName, $tier, $port, $tag, $cpuRequest, $cpuLimit, $changeCause) {

Set-Content  -Path "$tempDir/deploy-$deployName.yaml" -Value "
apiVersion: apps/v1 #  for k8s versions before 1.9.0 use apps/v1beta2  and before 1.8.0 use extensions/v1beta1
kind: Deployment
metadata:
  name:  $deployName
  annotations:
    kubernetes.io/change-cause: $changeCause
spec:
  selector:
    matchLabels:
      app:   $deployName
      tier:  $tier
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app:  $deployName
        tier: $tier
    spec:
      containers:
      - name:  $deployName
        image: $acrName.azurecr.io/repo/$deployName`:$tag
        imagePullPolicy: Always
        resources:
          requests:
            cpu: $cpuRequest
            memory: 100Mi
          limits:
            cpu: $cpuLimit
        env:
        - name: GET_HOSTS_FROM
          value: dns
          # If your cluster config does not include a dns service, then to
          # instead access environment variables to find service host
          # info, comment out the 'value: dns' line above, and uncomment the
          # line below:
          # value: env
        ports:
        - containerPort: $port
        readinessProbe:
          httpGet:
             path: /
             port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 1
          successThreshold: 1
          failureThreshold: 2
"
}
# ----------------------------------------------------------------------------------
function set-SecretProviderClass ($secretProviderClassName, $tempDir, $keyVaultName, $secret2Name, $secret2Alias, $resourceGroupName, $subscriptionId, $tenantId) {

Set-Content  -Path "$tempDir/SecretProviderClass.yaml" -Value "
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: $($secretProviderClassName)
spec:
  provider: azure
  parameters:
    usePodIdentity: ""true""
    useVMManagedIdentity: ""false""
    userAssignedIdentityID: """"
    keyvaultName: $keyVaultName
    cloudName: AzurePublicCloud
    objects:  |
      array:
        - | 
          objectName: $secret2Name
          objectAlias: $secret2Alias
          objectType: secret
          objectVersion: """"
    resourceGroup: $resourceGroupName
    subscriptionId: $subscriptionId
    tenantId: $tenantId
"
}
# --------------------------------------------
function set-addpodidentity ($identityName, $tempDir, $identity, $identitySelector) {

Set-Content  -Path "$tempDir/addpodidentity.yaml" -Value "
apiVersion: aadpodidentity.k8s.io/v1
kind: AzureIdentity
metadata:
  name: $($identityName)
spec:
  type: 0
  resourceID: $($identity.id)
  clientID: $($identity.clientId)
---
apiVersion: aadpodidentity.k8s.io/v1
kind: AzureIdentityBinding
metadata:
  name: $($identityName)-binding
spec:
  azureIdentity: $($identityName)
  selector: $($identitySelector)
"
}

# -----------------------------------------------------------------------------------

function set-podTest ($tempDir, $secretProviderClassName, $identitySelector) {

Set-Content  -Path "$tempDir/podTest.yaml" -Value "
kind: Pod
apiVersion: v1
metadata:
  name: nginx-secrets-store
  labels:
    aadpodidbinding: $($identitySelector)
spec:
  containers:
    - name: nginx
      image: nginx
      volumeMounts:
      - name: secrets-store-inline
        mountPath: /mnt/secrets-store
        readOnly: true
  volumes:
    - name: secrets-store-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
            secretProviderClass: $($secretProviderClassName)
"
}
#--------------------------------------------------------------------------------------
function set-DeploymentMSIKv ($acrName, $tempDir, $deployName, $tier, $port, $tag, $cpuRequest, $cpuLimit, $changeCause, $identitySelector ) {

Set-Content  -Path "$tempDir/deploy-$deployName.yaml" -Value "
apiVersion: apps/v1 #  for k8s versions before 1.9.0 use apps/v1beta2  and before 1.8.0 use extensions/v1beta1
kind: Deployment
metadata:
  name:  $deployName
  annotations:
    kubernetes.io/change-cause: $changeCause
spec:
  selector:
    matchLabels:
      app:   $deployName
      tier:  $tier
  replicas: 1
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 25%
  template:
    metadata:
      labels:
        app:  $deployName
        tier: $tier
        aadpodidbinding: $($identitySelector)
    spec:
      containers:
      - name:  $deployName
        image: $acrName.azurecr.io/repo/$deployName`:$tag
        imagePullPolicy: Always
        resources:
          requests:
            cpu: $cpuRequest
            memory: 100Mi
          limits:
            cpu: $cpuLimit
        env:
        - name: GET_HOSTS_FROM
          value: dns
          # If your cluster config does not include a dns service, then to
          # instead access environment variables to find service host
          # info, comment out the 'value: dns' line above, and uncomment the
          # line below:
          # value: env
        ports:
        - containerPort: $port     
"
}
# ----------------------------------------------------------------------------------------
function set-DeploymentOauth ($tempDir, $deployName, $tenantId, $appPassword, $frontFQDN, $oauthAppID) {

Set-Content  -Path "$tempDir/deploy-$deployName.yaml" -Value "
apiVersion: apps/v1
kind: Deployment
metadata:
  name: oauth2-proxy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: oauth2-proxy
  template:
    metadata:
      labels:
        app: oauth2-proxy
    spec:
      containers:
      - env:
          - name: OAUTH2_PROXY_PROVIDER
            value: azure
          - name: OAUTH2_PROXY_AZURE_TENANT
            value: $tenantId
          - name: OAUTH2_PROXY_CLIENT_ID
            value: $oauthAppID 
          - name: OAUTH2_PROXY_CLIENT_SECRET
            value: $appPassword
          - name: OAUTH2_PROXY_COOKIE_SECRET
            value: somethingveryran
          - name: OAUTH2_PROXY_HTTP_ADDRESS
            value: ""0.0.0.0:4180""
          - name: OAUTH2_PROXY_UPSTREAM
            value: ""https://$frontFQDN""
          - name: OAUTH2_PROXY_EMAIL_DOMAINS
            value:  '*'
        image: quay.io/pusher/oauth2_proxy:latest
        imagePullPolicy: Always
        name: oauth2-proxy
        ports:
        - containerPort: 4180
          protocol: TCP
  "
}
# ---------------------------------------------------

function set-ServiceOauth ($tempDir, $serviceName) {

Set-Content  -Path $tempDir"/service-$serviceName.yaml" -Value "

apiVersion: v1
kind: Service
metadata:
  name: oauth2-proxy
spec:
  ports:
  - name: http
    port: 4180
    protocol: TCP
    targetPort: 4180
  selector:
    app: oauth2-proxy
"
}

# ----------------------------------------------------------------
function set-IngressOauthProxy ($tempDir, $serviceName, $frontFQDN, $issuerName, $secretName) {

#$setServiceName = $serviceName + $suffix

Set-Content  -Path "$tempDir/ingress-$serviceName.yaml" -Value "
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: oauth2-proxy-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/issuer: $issuerName
spec:
  tls:
  - hosts:
    - $frontFQDN
    secretName: $secretName
  rules:
  - host: $frontFQDN
    http:
      paths:
      - path: /oauth2
        backend:
          serviceName: oauth2-proxy
          servicePort: 4180
"
}
# ---------------------------------------------------------------
function set-IngressFrontendOauth ($tempDir, $serviceName, $frontFQDN, $issuerName) {

#$setServiceName = $serviceName + $suffix

Set-Content  -Path "$tempDir/ingress-$serviceName.yaml" -Value "
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: frontend-oauth2-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/auth-url: ""http://oauth2-proxy.default.svc.cluster.local:4180/oauth2/auth""
    nginx.ingress.kubernetes.io/auth-signin: ""http://$frontFQDN/oauth2/start""
spec:
  rules:
  - host: $frontFQDN
    http:
      paths:
      - path: /
        backend:
          serviceName: mvcmoviefrontend
          servicePort: 80
"
}
# ----------
function set-BuildPipeline ($acrName, $ServiceConnectionID) {

Set-Content  -Path "/workspace/frontend/pipeline-build.yaml" -Value "
# Docker
# Build and push an image to Azure Container Registry
# https://docs.microsoft.com/azure/devops/pipelines/languages/docker

trigger:
- master

resources:
- repo: self

variables:
  # Container registry service connection established during pipeline creation
  dockerRegistryServiceConnection: '$ServiceConnectionID'
  imageRepository: 'repo/mvcmoviefrontend'
  containerRegistry: '$acrName.azurecr.io'
  dockerfilePath: '`$(Build.SourcesDirectory)/Dockerfile'
  tag: '`$(Build.BuildNumber)'

  # Agent VM image name
  vmImageName: 'ubuntu-latest'

stages:
- stage: Build
  displayName: Build and push stage
  jobs:
  - job: Build
    displayName: Build
    pool:
      vmImage: `$(vmImageName)
    steps:
    - task: Docker@2
      displayName: Build and push an image to container registry
      inputs:
        command: buildAndPush
        repository: `$(imageRepository)
        dockerfile: `$(dockerfilePath)
        containerRegistry: `$(dockerRegistryServiceConnection)
        tags: |
          `$(tag)
    - task: CopyFiles@2
      displayName: Copy yaml deployment file to `$(Build.ArtifactStagingDirectory)
      inputs:
        Contents: 'deploy-mvcmoviefrontend.yaml'
        TargetFolder: '`$(Build.ArtifactStagingDirectory)'
    - task: PublishBuildArtifacts@1
      inputs:
        PathtoPublish: '`$(Build.ArtifactStagingDirectory)'
        ArtifactName: 'drop'
        publishLocation: 'Container'
"
}
### --------------------------------------------------------------------------------

function set-Deployment-Frontend-CD ($acrName) {

Set-Content  -Path "/workspace/frontend/deploy-mvcmoviefrontend.yaml" -Value "

apiVersion: apps/v1 #  for k8s versions before 1.9.0 use apps/v1beta2  and before 1.8.0 use extensions/v1beta1
kind: Deployment
metadata:
  name:  mvcmoviefrontend
  annotations:
    kubernetes.io/change-cause: initial Deployment with build ID #{Build.BuildNumber}#
spec:
  selector:
    matchLabels:
      app:   mvcmoviefrontend
      tier:  frontend
  replicas:
  template:
    metadata:
      labels:
        app:  mvcmoviefrontend
        tier: frontend
    spec:
      containers:
      - name:  mvcmoviefrontend
        image: #{acrName}#.azurecr.io/repo/mvcmoviefrontend:#{Build.BuildNumber}#
        imagePullPolicy: Always
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
          limits:
            cpu: 1000m
        env:
        - name: GET_HOSTS_FROM
          value: dns
          # If your cluster config does not include a dns service, then to
          # instead access environment variables to find service host
          # info, comment out the 'value: dns' line above, and uncomment the
          # line below:
          # value: env
        ports:
        - containerPort: 80
"
}
# ---------------------------------------------
function set-homeFrontendCD ($suffix, $GreetingMessage) {

Set-Content  -Path "/workspace/frontend/Views/Home/Index.cshtml" -Value "
@{
    ViewData[""Title""] = ""Home Page"";
}

<div class=""text-center"">
    <h1 class=""display-4"">$GreetingMessage</h1>
    <p>Learn about <a href=""https://docs.microsoft.com/aspnet/core"">building Web apps with ASP.NET Core</a>.</p>

    <img src=""https://storageaccountxx$suffix.blob.core.windows.net/aksblobcontainer$suffix/microsoft-azure-logo.jpg"" alt=""microsoft-azure-logo"">
</div>
"
}

## ----------------------------------------------------------------------
function set-StartupCS-KeyVault ($suffix,$microServiceDir) {

Set-Content  -Path "$microServiceDir/moviesAPI_get/Startup.cs" -Value "
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.HttpsPolicy;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using moviesAPI.Models;
using Microsoft.EntityFrameworkCore;
using moviesAPI.Data;
using Pomelo.EntityFrameworkCore.MySql;
using Microsoft.Azure.Services.AppAuthentication;
using Azure.Identity;
using Azure.Core;
using Azure.Security.KeyVault.Secrets;




namespace moviesAPI
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddControllers();
          //services.AddDbContext<MvcMovieContext>(options => options.UseMySql(Configuration.GetConnectionString(""MvcMovieContext"")));

            var kvUri = ""https://keyvaultaks$suffix.vault.azure.net/"";
            var client = new SecretClient(new Uri(kvUri), new DefaultAzureCredential());
            KeyVaultSecret secret = client.GetSecret(""connectionString"");
         
            services.AddDbContext<MvcMovieContext>(options => options.UseMySql(secret.Value));
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app.UseCors(builder =>
            {
                builder
                .AllowAnyOrigin()
                .AllowAnyMethod()
                .AllowAnyHeader();
            });

            app.UseHttpsRedirection();

            app.UseRouting();

            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
        }
    }
}
"
}

#-----------------------------------------------------------------------------------
function set-Appsettings-NoConnectionString ($suffix, $microServiceDir, $api, $port  ) {
##param([string]$suffix , [string]$microServiceDir , [string]$api , [string]$port) 

 Set-Content  -Path "$microServiceDir/$api/appsettings.json" -Value "
{
  ""Logging"": {
    ""LogLevel"": {
      ""Default"": ""Information"",
      ""Microsoft"": ""Warning"",
      ""Microsoft.Hosting.Lifetime"": ""Information""
    }
  },
  ""AllowedHosts"": ""*"",
  ""urls"": ""http://0.0.0.0:$port""
}
"
}