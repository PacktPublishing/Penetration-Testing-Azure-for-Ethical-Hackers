$upnsuffix=$(az ad signed-in-user show --query userPrincipalName --output tsv | sed 's/.*@//')
$password = Read-Host "Please enter a password"
$securepassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$users = "sandra@$upnsuffix","mike@$upnsuffix","juan@$upnsuffix","kwasi@$upnsuffix","adaeze@$upnsuffix"

foreach ($user in $users) 
{ 
    $displayname=$(echo $user | sed 's/@.*//')
    New-AzADUser -DisplayName $displayname -UserPrincipalName $user -Password $securepassword -MailNickname $displayname
}
echo "Successfully created the following users:" $users
echo "User Password:" $password