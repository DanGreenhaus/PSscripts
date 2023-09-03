PowerShell

Copy
PS C:\> Get-ADPrincipalGroupMembership -Identity Administrator


distinguishedName : CN=Domain Users,CN=Users,DC=Fabrikam,DC=com
GroupCategory     : Security
GroupScope        : Global
name              : Domain Users
objectClass       : group
objectGUID        : 86c0f0d5-8b4d-4f35-a867-85a006b92902
SamAccountName    : Domain Users
SID               : S-1-5-21-41432690-3719764436-1984117282-513

distinguishedName : CN=Administrators,CN=Builtin,DC=Fabrikam,DC=com
GroupCategory     : Security
GroupScope        : DomainLocal
name              : Administrators
objectClass       : group
objectGUID        : 02ce3874-dd86-41ba-bddc-013f34019978
SamAccountName    : Administrators
SID               : S-1-5-32-544
