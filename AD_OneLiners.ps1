#look up AD group based on description
Get-ADPrincipalGroupMembership "<username>" | Get-ADGroup -Properties Description  | Where-Object {$_.description -like '*<app name>*'}


#look up AD group based on description
$email="<insert email address here>"
$appname="kenna"
Get-ADPrincipalGroupMembership -Identity (get-aduser -Filter {emailaddress -eq $email}).sAMAccountName | Get-ADGroup -Properties Description  | Where-Object {$_.description -like "*$appname*"}

Get-ADPrincipalGroupMembership "<insert username>" | Get-ADGroup -Properties Description  <#| Where-Object {$_.description -like '*app*'}#>  | Sort-Object -descending | select-object name, description

#look up username from email address
$email="<email address>"
$Newuser= (get-aduser -Filter {emailaddress -eq $email}).sAMAccountName
$existinguser="<username>"
# to compare two users
Compare-Object -ReferenceObject (Get-AdPrincipalGroupMembership $Newuser | select name | sort-object -Property name) -DifferenceObject (Get-AdPrincipalGroupMembership $existinguser | Select-Object name | sort-object -Property name) -property name -passthru


$Results = Get-ADUser -Identity "<username>" -Properties DisplayName, businessCategory, Department, EmailAddress, physicalDeliveryOfficeName, Manager
$Results
Get-AdUser -Filter {distinguishedName -eq $Results.Manager} -properties *| Select-Object @{L=’Manager’;E={(Get-ADUser "$_").DisplayName}}
@{L=’name’;E={$_.processname}},

(Get-ADUser "CN=<username>,CN=<>,DC=<domain controller>,DC=<Domain controller extension").DisplayName

