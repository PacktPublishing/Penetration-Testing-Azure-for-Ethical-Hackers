$starttime = Get-Date
Write-Host -ForegroundColor Green "Deployment Started $starttime"

## Create contributoruser
$upnsuffix=$(az ad signed-in-user show --query userPrincipalName --output tsv | sed 's/.*@//')
$password = Read-Host "Please enter a password"
# $location = Read-Host "Please enter a location E.g. uksouth, eastus, westeurope"
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
$random = Get-Random -Maximum 10000
$random2 = Get-Random -Maximum 100
$webappname = "webapp$random"
$keyvaultname = "azptkv$random"
$aciname = "aci$random"
$storagename = "pubstore$random$random2"
$cosmosname = "cosmos$random"
$sqlsrvname = "sqlsrv$random"
$acrname="acr$random"
$location = "uksouth"
$gitrepo = "https://github.com/Azure-Samples/php-docs-hello-world"
az group create --name $group --location $location

## obtain subscription id
$subid=$(az account show --query id --output tsv)
$signedinuserid=$(az ad signed-in-user show --query objectId -o tsv)

## create webapp with owner permissions
Write-Host -ForegroundColor Green "######################################"
Write-Host -ForegroundColor Green "# Creating WebApp #"
Write-Host -ForegroundColor Green "######################################"
az appservice plan create -n $webappname -g $group --sku S1
az webapp create -n $webappname -g $group --plan $webappname
az webapp deployment source config -n $webappname -g $group --repo-url $gitrepo --branch master --manual-integration
az webapp identity assign -n $webappname -g $group --role Owner --scope /subscriptions/$subid

## Create key vault
Write-Host -ForegroundColor Green "######################################"
Write-Host -ForegroundColor Green "# Creating Key Vault #"
Write-Host -ForegroundColor Green "######################################"
az keyvault create -n $keyvaultname -g $group --location $location
az keyvault secret set --vault-name $keyvaultname --name "twitter-api-key" --value "LB7BsQCtG57xYkQG" --description "Twitter API Key Used By ACI" 
az keyvault secret set --vault-name $keyvaultname --name "SQLAdminPassword" --value "4zVDknE3TyMxxW2J"
az keyvault secret set --vault-name $keyvaultname --name "db-encrption-key" --value "Pnfcc4F29XKNM5QB" --description "Database Encryption Key"
az keyvault key create --vault-name $keyvaultname --name "disk-encryption-key" --protection software

## Create container group with system-managed identity
az container create -g $group -n $aciname --image mcr.microsoft.com/azure-cli --assign-identity --scope /subscriptions/$subid --command-line "tail -f /dev/null"

## Create storage
Write-Host -ForegroundColor Green "########################################"
Write-Host -ForegroundColor Green "# Creating Storage Account #"
Write-Host -ForegroundColor Green "########################################"
az storage account create --name $storagename -g $group --location $location --sku Standard_LRS
az storage container create --account-name $storagename --name data --auth-mode login

Invoke-WebRequest https://raw.githubusercontent.com/davidokeyode/azure-offensive/master/sensitive_customer_private_information.csv -O sensitive_customer_private_information.csv 

az role assignment create --role "Storage Blob Data Contributor" --assignee $signedinuserid --scope "/subscriptions/$subid/resourceGroups/$group/providers/Microsoft.Storage/storageAccounts/$storagename"

az storage blob upload --account-name $storagename --container-name data --name sensitive_customer_private_information.csv --file sensitive_customer_private_information.csv --auth-mode login

# az storage account update -g $group --name $storagename --default-action Deny
# az storage account network-rule add -g $group --account-name $storagename --ip-address "16.17.18.19"

## Create Cosmos DB
Write-Host -ForegroundColor Green "######################################"
Write-Host -ForegroundColor Green "# Creating Cosmos DB #"
Write-Host -ForegroundColor Green "######################################"
az cosmosdb create -n $cosmosname -g $group --ip-range-filter "16.17.18.19"

## Create Azure SQL
Write-Host -ForegroundColor Green "######################################"
Write-Host -ForegroundColor Green "# Creating SQL Database #"
Write-Host -ForegroundColor Green "######################################"
az sql server create -l $location -g $group -n $sqlsrvname -u sqladminuser -p 4zVDknE3TyMxxW2J

az sql db create -g $group -s $sqlsrvname -n advworksDB --sample-name AdventureWorksLT --edition GeneralPurpose --family Gen4 --capacity 1 --zone-redundant false

az sql server firewall-rule create -g $group -s $sqlsrvname -n "corp-app-rule" --start-ip-address 16.17.18.19 --end-ip-address 16.17.18.19

# Get connection string for the database
$connstring=$(az sql db show-connection-string --name advworksDB --server $sqlsrvname --client ado.net --output tsv)
$connstring=$connstring -replace "<username>", "sqladminuser"
$connstring=$connstring -replace "<password>", "4zVDknE3TyMxxW2J"

az webapp config appsettings set --name $webappname -g $group --settings "SQLSRV_CONNSTR=$connstring" 

## Create container registry and container image
Write-Host -ForegroundColor Green "######################################"
Write-Host -ForegroundColor Green "# Creating Container Registry #"
Write-Host -ForegroundColor Green "######################################"
az acr create -g $group --location $location --name $acrname --sku Standard --admin-enabled true

## Create automation account
az deployment group create --name TemplateDeployment --resource-group $group --template-uri "https://raw.githubusercontent.com/PacktPublishing/Penetration-Testing-Azure-for-Ethical-Hackers/main/chapter-6/resources/automationacct.json"

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