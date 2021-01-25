$starttime = Get-Date
Write-Host -ForegroundColor Green "Deployment Started $starttime"

## Create victimadminuser
$upnsuffix=$(az ad signed-in-user show --query userPrincipalName --output tsv | sed 's/.*@//')
$password = Read-Host "Please enter a password"
$securepassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$user = "readeruser@$upnsuffix"
$displayname=$(echo $user | sed 's/@.*//')
Write-Host -ForegroundColor Green "###########################################################################"
Write-Host -ForegroundColor Green "# Creating new admin user $user in Azure AD #"
Write-Host -ForegroundColor Green "###########################################################################"
New-AzADUser -DisplayName $displayname -UserPrincipalName $user -Password $securepassword -MailNickname $displayname

## Assign role in Azure subscription
$subid=$(az account show --query id --output tsv)
Write-Host -ForegroundColor Green "####################################################################"
Write-Host -ForegroundColor Green "# Assigning the Reader role to $user #"
Write-Host -ForegroundColor Green "####################################################################"
az role assignment create --role "Reader" --assignee $user --subscription $subid

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