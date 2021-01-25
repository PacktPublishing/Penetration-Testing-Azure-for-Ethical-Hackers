## Delete Admin User
$upnsuffix=$(az ad signed-in-user show --query userPrincipalName --output tsv | sed 's/.*@//')
$user = "victimadminuser@$upnsuffix"
Write-Host -ForegroundColor Green "Removing the user $user"
Remove-AzADUser -UserPrincipalName $user -Confirm:$False -Force

## Delete Resource Group
$group = "pentest-rg"
Write-Host -ForegroundColor Green "Removing the resource group $group"
az group delete -n $group -y

## Script Output 
Write-Host -ForegroundColor Green "Successfully deleted the user $user"
Write-Host -ForegroundColor Green "Successfully deleted the resource group $group"