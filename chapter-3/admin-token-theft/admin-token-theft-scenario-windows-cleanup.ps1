## Delete Resource Group
$group = "pentest-rg"
Write-Host -ForegroundColor Green "Removing the resource group $group"
az group delete -n $group -y

## Script Output
Write-Host -ForegroundColor Green "Successfully deleted the resource group $group"