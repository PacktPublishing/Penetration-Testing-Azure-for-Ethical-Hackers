$starttime = Get-Date
Write-Host -ForegroundColor Green "Cleanup Started $starttime"

## Set the user and service principal names
import-module AzureAD.Standard.Preview
AzureAD.Standard.Preview\Connect-AzureAD -Identity -TenantID $env:ACC_TID
$upnsuffix=$(az ad signed-in-user show --query userPrincipalName --output tsv | sed 's/.*@//')
$owneruser = "owneruser@$upnsuffix"
$gauser = "globaladminuser@$upnsuffix"
$group = "pentest-rg"

## Get the app id and user id
$owneruserid=$(az ad user list --upn $owneruser --query [].objectId -o tsv)
$gauserid=$(az ad user list --upn $gauser --query [].objectId -o tsv)

## Clean up role assignments
Write-Host -ForegroundColor Green "###############################################################"
Write-Host -ForegroundColor Green "# Cleaning up role assignments #"
Write-Host -ForegroundColor Green "###############################################################"
az role assignment delete --assignee $owneruserid --role "Owner"

Write-Host -ForegroundColor Green "###############################################################"
Write-Host -ForegroundColor Green "# Cleaning up identity objects #"
Write-Host -ForegroundColor Green "###############################################################"
az ad user delete --id $owneruserid
az ad user delete --id $gauserid

# Write-Host -ForegroundColor Green "##############################################################"
# Write-Host -ForegroundColor Green "# Cleaning up resource group #"
# Write-Host -ForegroundColor Green "##############################################################"
# az group delete -n $group --yes
rm *.ps1
rm *.txt

Write-Host -ForegroundColor Green "Successfully cleaned up resources!!"