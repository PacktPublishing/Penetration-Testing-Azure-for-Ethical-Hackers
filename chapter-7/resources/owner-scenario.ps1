$starttime = Get-Date
Write-Host -ForegroundColor Green "Deployment Started $starttime"

## Create scenario users
$upnsuffix=$(az ad signed-in-user show --query userPrincipalName --output tsv | sed 's/.*@//')
$password = Read-Host "Please enter a password"
# $location = Read-Host "Please enter a location E.g. uksouth, eastus, westeurope"
$securepassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$gauser = "globaladminuser@$upnsuffix"
$owneruser = "owneruser@$upnsuffix"
$gadisplayname=$(echo $gauser | sed 's/@.*//')
$ownerdisplayname=$(echo $owneruser | sed 's/@.*//')
Write-Host -ForegroundColor Green "################################################################################################################"
Write-Host -ForegroundColor Green "# Creating new admin users $gauser and $owneruser in Azure AD #"
Write-Host -ForegroundColor Green "################################################################################################################"
New-AzADUser -DisplayName $gadisplayname -UserPrincipalName $gauser -Password $securepassword -MailNickname $gadisplayname
New-AzADUser -DisplayName $ownerdisplayname -UserPrincipalName $owneruser -Password $securepassword -MailNickname $ownerdisplayname


## assign global administrator role to user
$gauserid=$(az ad user list --upn $gauser --query [].objectId -o tsv)
$globaladminid=$((Get-AzureADDirectoryRole | where {$_.DisplayName -eq 'Global Administrator'}).ObjectId)
Add-AzureADDirectoryRoleMember -ObjectId $globaladminid -RefObjectId $gauserid

## assign role in Azure subscription
$subid=$(az account show --query id --output tsv)
Write-Host -ForegroundColor Green "#########################################################################"
Write-Host -ForegroundColor Green "# Assigning the Owner role to $owneruser #"
Write-Host -ForegroundColor Green "#########################################################################"
az role assignment create --role "Owner" --assignee $owneruser --subscription $subid

## Set variables and create resource group
$group = "pentest-rg"
$location = "uksouth"
az group create --name $group --location $location

## Script Output
Start-Transcript -Path owner-scenario-output.txt
Write-Host -ForegroundColor Green "#################################"
Write-Host -ForegroundColor Green "# Script Output #"
Write-Host -ForegroundColor Green "#################################"
Write-Host -ForegroundColor Green "Azure Global Admin User:" $gauser 
Write-Host -ForegroundColor Green "Azure Global Admin User Password:" $password
Write-Host -ForegroundColor Green "Azure Owner Admin User:" $owneruser
Write-Host -ForegroundColor Green "Azure Owner Admin User Password:" $password
Write-Host -ForegroundColor Green " "
Stop-Transcript
$endtime = Get-Date
Write-Host -ForegroundColor Green "Deployment Ended $endtime"