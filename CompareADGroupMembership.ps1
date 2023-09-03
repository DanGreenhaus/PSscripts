$user1="<user1>"
$user2="<user2>"
Compare-Object -ReferenceObject (Get-AdPrincipalGroupMembership $user1 | select name | sort-object -Property name) -DifferenceObject (Get-AdPrincipalGroupMembership $user2 | select name | sort-object -Property name) -property name -passthru 
