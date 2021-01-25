$starttime = Get-Date
Write-Host -ForegroundColor Green "Deployment Started $starttime"

## Create victimadminuser
$upnsuffix=$(az ad signed-in-user show --query userPrincipalName --output tsv | sed 's/.*@//')
$password = Read-Host "Please enter a password"
$securepassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$user = "victimadminuser@$upnsuffix"
$displayname=$(echo $user | sed 's/@.*//')
Write-Host -ForegroundColor Green "###########################################################################"
Write-Host -ForegroundColor Green "# Creating new admin user $user in Azure AD #"
Write-Host -ForegroundColor Green "###########################################################################"
New-AzADUser -DisplayName $displayname -UserPrincipalName $user -Password $securepassword -MailNickname $displayname

## Assign role in Azure subscription
$subid=$(az account show --query id --output tsv)
Write-Host -ForegroundColor Green "#########################################################################"
Write-Host -ForegroundColor Green "# Assigning the Contributor role to $user #"
Write-Host -ForegroundColor Green "#########################################################################"
az role assignment create --role "Contributor" --assignee $user --subscription $subid

## Create Storage account with SAS token
$group = "pentest-rg"
$location = "uksouth"
az group create --name $group --location $location
$random = Get-Random -Maximum 10000
$storagename = "pentest$random"
$containername = "exfil"
$blobname = "azureprofile.zip"
Write-Host -ForegroundColor Green "###############################################"
Write-Host -ForegroundColor Green "# Creating a new storage account $storagename #"
Write-Host -ForegroundColor Green "###############################################"
az storage account create --name $storagename --resource-group $group --location $location --sku Standard_LRS --allow-blob-public-access false --https-only true
Write-Host -ForegroundColor Green "######################################################"
Write-Host -ForegroundColor Green "# Creating a new blob container $containername in $storagename #"
Write-Host -ForegroundColor Green "######################################################"
az storage container create --account-name $storagename --name $containername
# $ctx = New-AzStorageContext -StorageAccountName $storagename -UseConnectedAccount
$ctx = (Get-AzStorageAccount -ResourceGroupName $group -AccountName $storagename).context
$StartTime = Get-Date
$EndTime = $startTime.AddDays(6)
# $sastoken = New-AzStorageContainerSASToken -Name $containername -Permission rwdlac -StartTime $StartTime -ExpiryTime $EndTime -context $ctx
$sastoken = New-AzStorageAccountSASToken -Service Blob -ResourceType Service,Container,Object -Permission "racwdlup" -Context $ctx -StartTime $StartTime -ExpiryTime $EndTime


## Download Windows Custom Script Extension
Invoke-WebRequest -Uri https://raw.githubusercontent.com/PacktPublishing/Implementing-Microsoft-Azure-Security-Technologies/main/chapter-3/custom-script-extensions/windows_custom_extension.json -OutFile windows_custom_extension.json

## Deploy Windows VM with Azure PowerShell installed (Output public IP)
$winvmname = "winvm$random"
$windowsuser = "windowsadmin"
Write-Host -ForegroundColor Green "########################################"
Write-Host -ForegroundColor Green "# Creating a new Windows VM $winvmname #"
Write-Host -ForegroundColor Green "########################################"
az vm create --resource-group $group --name $winvmname --image win2016datacenter --admin-username $windowsuser --admin-password $password --size Standard_D2s_v3
az vm open-port --port 3389 --resource-group $group --name $winvmname --priority 200
$winvmpubip=$(az vm show -d -g $group -n $winvmname --query publicIps -o tsv)

Set-AzVMCustomScriptExtension -ResourceGroupName $group -VMName $winvmname -Location $location -FileUri "https://raw.githubusercontent.com/PacktPublishing/Implementing-Microsoft-Azure-Security-Technologies/main/chapter-3/custom-script-extensions/azure_powershell_install.ps1" -Run 'azure_powershell_install.ps1' -Name AzurePSExtension

## Script Output
Start-Transcript -Path admin-token-theft-output.txt
Write-Host -ForegroundColor Green "#################"
Write-Host -ForegroundColor Green "# Script Output #"
Write-Host -ForegroundColor Green "#################"
Write-Host -ForegroundColor Green "Azure Admin User:" $user
Write-Host -ForegroundColor Green "Azure Admin User Password:" $password
Write-Host -ForegroundColor Green " "
Write-Host -ForegroundColor Green "Windows VM Public IP:" $winvmpubip
Write-Host -ForegroundColor Green "Windows VM Username:" $windowsuser
Write-Host -ForegroundColor Green "Windows VM User Password:" $password
Write-Host -ForegroundColor Green " "
Write-Host -ForegroundColor Green "Exfiltration Storage Location: https://$storagename.blob.core.windows.net/$containername/$blobname$sastoken"
Stop-Transcript
$endtime = Get-Date
Write-Host -ForegroundColor Green "Deployment Ended $endtime"
