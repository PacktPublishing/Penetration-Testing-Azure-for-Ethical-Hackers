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

## generate random number and application name
$random = Get-Random -Maximum 1000
$appname = "customapp"

## obtain subscription id
$subid=$(az account show --query id --output tsv)

## create service principal with contributor permissions
$customapp=$(az ad sp create-for-rbac -n $appname --role Contributor --scopes /subscriptions/$subid)

## Get the app id and user id
$appid=$(az ad app list --display-name $appname --query [].appId -o tsv)
$userid=$(az ad user list --upn $user --query [].objectId -o tsv)

## Assign reader user as application owner
az ad app owner add --id $appid --owner-object-id $userid

# Deploy ARM Template
$group = "pentest-rg"
$location = "uksouth"
az group create --name $group --location $location
az deployment group create --name VMDeployment --resource-group $group --template-uri "https://raw.githubusercontent.com/PacktPublishing/Penetration-Testing-Azure-for-Ethical-Hackers/main/chapter-4/resources/badtemplate.json"

## Script Output
Start-Transcript -Path reader-account-output.txt
Write-Host -ForegroundColor Green "#################"
Write-Host -ForegroundColor Green "# Script Output #"
Write-Host -ForegroundColor Green "#################"
Write-Host -ForegroundColor Green "Azure Reader Admin User:" $user
Write-Host -ForegroundColor Green "Azure Reader Admin User Password:" $password
Write-Host -ForegroundColor Green " "
Stop-Transcript
$endtime = Get-Date
Write-Host -ForegroundColor Green "Deployment Ended $endtime"