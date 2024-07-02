#this section is so you can quiery multiple OUs
$ADtopLevelOU = "distinguished name of OU"
$ADtopLevelOU = "distinguished name of OU"
$ADtopLevelOU = "distinguished name of OU"


$Server="<domain controler 1"
$server="<domain controler 2"

Get-ADObject -server $Server -searchbase $ADtopLevelOU -Filter { (objectClass -eq "organizationalUnit") } |
    ForEach-Object {
        Get-ADComputer -server $Server -Filter * -SearchBase ($_.distinguishedName) | Select-Object name, dnshostname, distinguishedName | export-csv .\<insert Filename here> -NoTypeInformation -Append
    }
    
