$starttime = Get-Date
Write-Host -ForegroundColor Green "Deployment Started $starttime"

## Create readeruser
$upnsuffix=$(az ad signed-in-user show --query userPrincipalName --output tsv | sed 's/.*@//')
$password = Read-Host "Please enter a password"
$securepassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$user = "readeruser@$upnsuffix"
$displayname=$(echo $user | sed 's/@.*//')
Write-Host -ForegroundColor Green "###########################################################################"
Write-Host -ForegroundColor Green "# Creating new admin user $user in Azure AD #"
Write-Host -ForegroundColor Green "###########################################################################"
New-AzADUser -DisplayName $displayname -UserPrincipalName $user -Password $securepassword -MailNickname $displayname

## assign role in Azure subscription
$subid=$(az account show --query id --output tsv)
Write-Host -ForegroundColor Green "####################################################################"
Write-Host -ForegroundColor Green "# Assigning the Reader role to $user #"
Write-Host -ForegroundColor Green "####################################################################"
az role assignment create --role "Reader" --assignee $user --subscription $subid

## Set variables and create resource group
$random = Get-Random -Maximum 100000 -Minimum 10000
$customappname = "customapp"
$containerappname = "containerapp"
$acrname="acr$random"
$group = "pentest-rg"
$location = "uksouth"
az group create --name $group --location $location

## obtain subscription id
$subid=$(az account show --query id --output tsv)

## create service principals with contributor permissions
$customapp=$(az ad sp create-for-rbac -n $customappname --role Contributor --scopes /subscriptions/$subid)
$containerapp=$(az ad sp create-for-rbac -n $containerappname --role Contributor --scopes /subscriptions/$subid)

## Get the app id and user id
$customappid=$(az ad app list --display-name $customappname --query [].appId -o tsv)
$containerappid=$(echo $containerapp | jq -r .appId)
$containerappsecret=$(echo $containerapp | jq -r .password)
$tenantid=$(echo $containerapp | jq -r .tenant)
$userid=$(az ad user list --upn $user --query [].objectId -o tsv)

## Download Docker file
Invoke-WebRequest -Uri https://raw.githubusercontent.com/PacktPublishing/Penetration-Testing-Azure-for-Ethical-Hackers/main/chapter-4/resources/Dockerfile -OutFile Dockerfile

## Modify Docker file
sed -i 's/"$containerappid"/"'"$containerappid"'"/' Dockerfile
sed -i 's/"$containerappsecret"/"'"$containerappsecret"'"/' Dockerfile
sed -i 's/"$tenantid"/"'"$tenantid"'"/' Dockerfile

## Create container registry and container image
az acr create --resource-group $group --location $location --name $acrname --sku Standard

az acr build --resource-group $group --registry $acrname --image nodeapp-web:v1 .

## Assign reader user as application owner
az ad app owner add --id $customappid --owner-object-id $userid

# Deploy ARM Template
az deployment group create --name TemplateDeployment --resource-group $group --template-uri "https://raw.githubusercontent.com/PacktPublishing/Penetration-Testing-Azure-for-Ethical-Hackers/main/chapter-4/resources/badtemplate.json"

az vm identity assign -g $group -n LinuxVM --role Contributor --scope /subscriptions/$subid

## Script Output
Start-Transcript -Path reader-account-output.txt
Write-Host -ForegroundColor Green "#################"
Write-Host -ForegroundColor Green "# Script Output #"
Write-Host -ForegroundColor Green "#################"
Write-Host -ForegroundColor Green "Azure Reader User:" $user
Write-Host -ForegroundColor Green "Azure Reader User Password:" $password
Write-Host -ForegroundColor Green " "
Stop-Transcript
$endtime = Get-Date
Write-Host -ForegroundColor Green "Deployment Ended $endtime"