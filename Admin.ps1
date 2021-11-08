#To created saved credentials with a single user
$User = "<Domain>\<USERNAME>"

$PWord = ConvertTo-SecureString -String "<insert password here>" -AsPlainText -Force

$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
$Cred| Export-CliXml -Path "C:\Users\<username>\Documents\Admin.Cred"

#To create a single cred file with multiple saved credentials############################################
#reference: https://www.jaapbrasser.com/quickly-and-securely-storing-your-credentials-powershell/
$D1User = "<Domain>\<USERNAME>"

$PWord1 = ConvertTo-SecureString -String "<insert password here>" -AsPlainText -Force

$D1 = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $D1User, $PWord1

$D2User = "<Domain>\<USERNAME>"

$PWord2 = ConvertTo-SecureString -String "<insert password here>" -AsPlainText -Force

$D2 = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $D2User, $PWord2

$Hash = @{

'Domain1' = $D1

'Domain2'= $D2

}

$Hash | Export-CliXml -Path "C:\Users\<username>\Documents\Admin.Cred"

