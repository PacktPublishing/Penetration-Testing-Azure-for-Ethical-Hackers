$starttime = Get-Date
Write-Host -ForegroundColor Green "Deployment Started $starttime"

## Set the user and service principal names
$upnsuffix=$(az ad signed-in-user show --query userPrincipalName --output tsv | sed 's/.*@//')
$user = "readeruser@$upnsuffix"
$appname = "customapp"

## Get the app id and user id
$appid=$(az ad app list --display-name $appname --query [].appId -o tsv)
$userid=$(az ad user list --upn $user --query [].objectId -o tsv)

## Clean up role assignments
Write-Host -ForegroundColor Green "####################################################################"
Write-Host -ForegroundColor Green "# Cleaning up role assignments #"
Write-Host -ForegroundColor Green "####################################################################"
az role assignment delete --assignee $appid --role "Contributor"
az role assignment delete --assignee $userid --role "Reader"

Write-Host -ForegroundColor Green "####################################################################"
Write-Host -ForegroundColor Green "# Cleaning up identity objects #"
Write-Host -ForegroundColor Green "####################################################################"
az ad app delete --id $appid
az ad user delete --id $userid


