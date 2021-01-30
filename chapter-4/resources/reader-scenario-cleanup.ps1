$starttime = Get-Date
Write-Host -ForegroundColor Green "Cleanup Started $starttime"

## Set the user and service principal names
$upnsuffix=$(az ad signed-in-user show --query userPrincipalName --output tsv | sed 's/.*@//')
$user = "readeruser@$upnsuffix"
$customappname = "customapp"
$containerappname = "containerapp"
$group = "pentest-rg"

## Get the app id and user id
$customappid=$(az ad app list --display-name $customappname --query [].appId -o tsv)
$containerappid=$(az ad app list --display-name $containerappname --query [].appId -o tsv)
$userid=$(az ad user list --upn $user --query [].objectId -o tsv)
$managedidentity=$(az ad sp list --display-name LinuxVM --query [].appId -o tsv)

## Clean up role assignments
Write-Host -ForegroundColor Green "#######################################"
Write-Host -ForegroundColor Green "# Cleaning up role assignments #"
Write-Host -ForegroundColor Green "#######################################"
az role assignment delete --assignee $customappid --role "Contributor"
az role assignment delete --assignee $containerappid --role "Contributor"
az role assignment delete --assignee $userid --role "Reader"
az role assignment delete --assignee $managedidentity --role "Contributor"

Write-Host -ForegroundColor Green "#######################################"
Write-Host -ForegroundColor Green "# Cleaning up identity objects #"
Write-Host -ForegroundColor Green "#######################################"
az ad app delete --id $customappid
az ad app delete --id $containerappid
az ad user delete --id $userid

Write-Host -ForegroundColor Green "#######################################"
Write-Host -ForegroundColor Green "# Cleaning up resource group #"
Write-Host -ForegroundColor Green "#######################################"
az group delete -n $group --yes
rm *.ps1
rm *.txt
rm Dockerfile

Write-Host -ForegroundColor Green "Successfully cleaned up resources!!"