$starttime = Get-Date
Write-Host -ForegroundColor Green "Cleanup Started $starttime"

## Set the user and service principal names
$upnsuffix=$(az ad signed-in-user show --query userPrincipalName --output tsv | sed 's/.*@//')
$user = "contributoruser@$upnsuffix"
$group = "pentest-rg"

## Get the app id and user id
$userid=$(az ad user list --upn $user --query [].objectId -o tsv)
$managedidentity=$(az ad sp list --display-name winvm01 --query [].appId -o tsv)

## Clean up role assignments
Write-Host -ForegroundColor Green "#######################################"
Write-Host -ForegroundColor Green "# Cleaning up role assignments #"
Write-Host -ForegroundColor Green "#######################################"
az role assignment delete --assignee $userid --role "Contributor"
az role assignment delete --assignee $managedidentity --role "Contributor"

Write-Host -ForegroundColor Green "#######################################"
Write-Host -ForegroundColor Green "# Cleaning up identity objects #"
Write-Host -ForegroundColor Green "#######################################"
az ad user delete --id $userid

Write-Host -ForegroundColor Green "#######################################"
Write-Host -ForegroundColor Green "# Cleaning up resource group #"
Write-Host -ForegroundColor Green "#######################################"
az group delete -n $group --yes
rm *.ps1
rm *.txt

Write-Host -ForegroundColor Green "Successfully cleaned up resources!!"