$starttime = Get-Date
Write-Host -ForegroundColor Green "Deployment Started $starttime"

## Create contributoruser
$upnsuffix=$(az ad signed-in-user show --query userPrincipalName --output tsv | sed 's/.*@//')
$password = Read-Host "Please enter a password"
$securepassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$user = "contributoruser@$upnsuffix"
$displayname=$(echo $user | sed 's/@.*//')
Write-Host -ForegroundColor Green "###########################################################################"
Write-Host -ForegroundColor Green "# Creating new admin user $user in Azure AD #"
Write-Host -ForegroundColor Green "###########################################################################"
New-AzADUser -DisplayName $displayname -UserPrincipalName $user -Password $securepassword -MailNickname $displayname

## assign role in Azure subscription
$subid=$(az account show --query id --output tsv)
Write-Host -ForegroundColor Green "#########################################################################"
Write-Host -ForegroundColor Green "# Assigning the Contributor role to $user #"
Write-Host -ForegroundColor Green "#########################################################################"
az role assignment create --role "Contributor" --assignee $user --subscription $subid

## Set variables and create resource group
$group = "pentest-rg"
$location = "uksouth"
$vm1name = "winvm01"
$vm2name = "winvm02"
$vm3name = "linuxvm01"
az group create --name $group --location $location

## obtain subscription id
$subid=$(az account show --query id --output tsv)

## create vms with contributor permissions
az vm create -g $group -n $vm1name --image win2019datacenter --admin-username azureuser --admin-password $password
az vm create -g $group -n $vm2name --image win2019datacenter --admin-username azureuser --admin-password $password
az vm create -g $group -n $vm3name --image UbuntuLTS --admin-username azureuser --admin-password $password
az vm open-port --port 3389 --resource-group $group --name $vm1name
az vm open-port --port 3389 --resource-group $group --name $vm2name
az vm open-port --port 22 --resource-group $group --name $vm3name
az vm identity assign -g $group -n $vm1name --role Contributor --scope /subscriptions/$subid
az vm identity assign -g $group -n $vm3name --role Owner --scope /subscriptions/$subid
az vm deallocate --resource-group $group --name $vm2name

## Script Output
Start-Transcript -Path contributor-iaas-scenario-output.txt
Write-Host -ForegroundColor Green "#################################"
Write-Host -ForegroundColor Green "# Script Output #"
Write-Host -ForegroundColor Green "#################################"
Write-Host -ForegroundColor Green "Azure Contributor Admin User:" $user
Write-Host -ForegroundColor Green "Azure Contributor Admin User Password:" $password
Write-Host -ForegroundColor Green " "
Stop-Transcript
$endtime = Get-Date
Write-Host -ForegroundColor Green "Deployment Ended $endtime"