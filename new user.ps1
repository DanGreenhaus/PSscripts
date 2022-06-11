<#  
.SYNOPSIS  
    This script is used to create new user accounts for users
.DESCRIPTION  
    This script takes input from system support (or sys admins) and creates an AD object, leading to a uniform and consistant appearence and basic 
    group membership. The only requirement to run the script is it needs to be run from a machine on the windows domain, with an account that 
    has access to create AD objects.   
    
    Known issues:
        The user needs to have a valid manager in AD, or else the script will fail
        Not ever field has user data input validation 
        If system support doesn't have rights to add an admin group, it will show an error, but continue to create the accounts
        If the user has a hyphenated last name, the script will fail
        the copying of AD groups for a [[ ]] account must be from the same person whose groups are being copied on the [[ ]] side.
.INPUTS

No inputs can be piped to the script, however all of the needed variables will be prompted for

.OUTPUTS

After the script finishes, it returns all of the properties of the newly created domain1 AD object.

.NOTES  
    File Name    : new users.ps1 
    Author       : Dan Greenhaus
    Requires     : AD Module
    Date updated : 5/20/2021
    Version      : 2.2

.Version History
    2.21 - 5/20/21 fixed typo in $Address 
	2.2 - 5/20/21 Added option to set address for 100% remote workers
    2.1 - 5/17/21 re-enabled ability to copy AD groups from existing user, added If statement to allow a user to either manually add software access or copy from existing groups
    2.0 - 5/13/21 Added ability to add user to new AD groups based on Y/N questions
    1.91 - 5/12/21 Removed ability to copy AD groups at request of system support
    1.9 - 5/7/21 Added section where the user's share drive is created during the onboarding process.  Set ACL to allow proper access.
    1.8 - 5/04/21 created production script and test script; both scripts are the same, however the test creates users in the test OU, while production creates users in the standard OU
    1.71 - 5/4/21 created two interns using new user production script
    1.7 - 5/3/21 created validation loop to ensure phone number entered in 10 digits long
    1.61 - 5/3/31 fixed variable issue with proxy address variable
    1.6 - 5/3/21 added validation to new user name to ensure user doesn't already exist in AD
    1.5 - 5/3/21 added validation to ensure manager exist in AD.  This also requires that the manager have an account in [[ ]] if the user needs a [[ ]] account
    1.4 - 4/30/21 added validation to several fields, to ensure data entered was valid.  added seperate passwords for [[ ]] and [[ ]].  added known bugs section.  added ability to copy current user AD memberships
    1.32 - 4/29/21 removed manual entry for phone extention; now the last 4 of the phone will automaticaly be the phone extention.  changed email address field.
    1.31 - 4/29/21 fixed issue with proxy settings variable on [[ ]] employees.
    1.3 - 4/26/21 Added automatic 20 character password creation for new accounts.  added SIP field to user's proxy address.
    1.1 - added ability to assign additional group memberships, based on user input. 
    1.0 - created initial script.  prompted user for all data, and then populated fields in AD based on user data

.LINK  
#>
$TestOrStandard="Standard" #this setting determines if the OU is the production users OU of standard or the test OU of test

#this section prompts for the new employees name, and validates that the object doesn't already exist in AD
$doesuserexist=0
DO {
    $name =  read-host "Please enter the new user's First and Last Name"
    $Samname= $name -replace " ", '.'
    if ([bool] (Get-ADUser -filter {SAMaccountname -eq $samname})){Write-Warning "User with that name already exists in AD."}
    else {$doesuserexist=1}
    }While ($doesuserexist -eq 0)
$Fname, $Lname = $Name.Split() 

#This section validates that the new user's manager exists in AD enviornment.
$mgrvalid = 0 
DO {
$Managername =  read-host "Please enter the new user's Manager"
if ([bool] (Get-ADUser -filter {name -eq $Managername})){$mgrvalid=1}
else {Write-Warning "Invalid manager name! Manager does not exist in AD."}
}While ($mgrvalid -eq 0)

$Title = read-host "Please enter the new user's Title"
$dept =  read-host "Please enter the new user's Department"
$orgletter = (read-host "Enter the first letter of the user's employer: (L), (C), (M), (F)").ToUpper()
if ($orgletter -like "L"){
    $dualaccount = (read-host "If they are a [[ ]] employee, will they need a [[ ]] account to be created as well? (Y)es or (N)o").ToUpper()
    #this section validates that the employee's [[ ]] manager exists in [[ ]] AD
    if ($dualaccount -like "Y"){
        $Domainmgrvalid = 0 
        if ([bool] (Get-ADUser -server "[[domain]]" -filter {name -eq $Managername})){$Domainmgrvalid=1}
        else {Write-Warning "Current [[ ]] manager does not have a valid account in [[ ]] AD; issues will likely occur on the [[ ]] side "}
        }
}
#this section validates that the employee's manager exists in AD
if ($orgletter -like "C"){
    $Domainvalid = 0 
    if ([bool] (Get-ADUser -server "[[domain]]" -filter {name -eq $Managername})){$Domainmgrvalid=1}
    else {write-warning "Current manager does not have a valid account in AD; issues will likely occur on the side "}
    }

if ($orgletter -eq "L" -or $orgletter -eq "C"){
    $Location = (read-host "Please enter the Office Location: , , or ").ToUpper()
    }


$doyouhavephonenum = (read-host "Do you have the user's desk phone number? (Y)es or (N)o").ToUpper()
if ($doyouhavephonenum -eq "Y"){
    #This section validates that the phone number entered is 10 digits
    $validphone=0
    DO {
    $phone =  (read-host "Please enter the new employee's desk phone number using the format ##########").ToCharArray()
    if ($phone.Length -eq 10){$validphone=1}
    else {Write-Warning "Invalid phone number!  Please try again"}
    }While ($validphone -eq 0)
    $ofcphone = "+1("+($phone[0])+($phone[1])+($phone[2])+")."+($phone[3])+($phone[4])+($phone[5])+"."+($phone[6])+($phone[7])+($phone[8])+($phone[9])
    $ipphone =  ($phone[6])+($phone[7])+($phone[8])+($phone[9])

}elseif ($doyouhavephonenum -eq "N") {
    #If the answer is no, 7777777777 is put in as the default number;
    #this allows the SAs to query all unentered numbers using powershell CMD "Get-ADUser -Filter 'OfficePhone -eq 7777777777' | Fl name, DistinguishedName"
    $ofcphone = "7777777777"
    $ipphone = "7777"
}

$copy = (read-host "Do you want to copy the group memberships from an existing user? (Y)es or (N)o").ToUpper()
#this section validates that the user that is being copied exists in AD
if ($copy -like "Y"){
    if ($orgletter -eq "L"){
    $copyuservalid = 0 
        DO {
            $ADGroupsfromuser = (read-host "Please enter the username to copy the groups") -replace " ", '.'
            if ([bool] (Get-ADUser -filter {SAMaccountname -eq $ADGroupsfromuser})){$copyuservalid=1}
            else {write-host "Invalid user entered! User does not exist in AD."}
        }While ($copyuservalid -eq 0)
    }
#this section validates that the account that the user will be copying group memberships from exists in AD
}
if ($copy -like "Y"){
    if($orgletter -like "C" -or $dualaccount -like "Y"){
        do{
        $copyuservalid=0
        $ADGroupsfromuser = (read-host "Please enter the username now to copy the Groups") -replace " ", '.'
        if ([bool] (Get-ADUser -Server [[domain]] -filter {SAMaccountname -eq $ADGroupsfromuser})){$copyuservalid=1}
        else {write-warning "Invalid user entered! User does not exist in AD."
             $ADGroupsfromuser = (read-host "If you want to copy the current AD groups from an existing user, please enter the user's name now") -replace " ", '.'}
        }While ($copyuservalid -eq 0)
    }
 }
#if user does not want to copy from an existing user, prompt for the following AD group memberships.
 if ($copy -like "N"){

    $Adobe = (read-host "What version of Adobe should be installed?  (S)tandard, (P)ro, (C)reative Cloud").ToUpper()

    $TicketingGroup=0
    $Samanage = (read-host "Does the user need to be added to a specific ticketing group?  (Y)es, (N)o").ToUpper()
    if ($Samanage -like "Y"){
        Write-Host ("Available  groups
        [[List]])
        $TicketingGroup = (read-host "Enter the number of the group that the user should be added to")
    }

    $docusign = (read-host "Docusign Access?  (Y)es, (N)o").ToUpper()
    if ($docusign -like "Y"){
        $docusignCo = (read-host "Docusign Access for which companies?").ToUpper()
    }

    $sharefileYN = (read-host "Sharefile Access?  (Y)es, (N)o").ToUpper()
    if ($sharefileYN -like "Y"){
        $sharefile = (read-host "Sharefile Access for which companies?").ToUpper()
    }

    
    $Salesforce = (read-host "Salesforce Access? (Y)es, (N)o").ToUpper()
    if ($Salesforce -like "Y"){
       $SalesforceRole = (read-host "What is their access level? ").ToUpper()
    }

 
}

    Add-Type -AssemblyName 'System.Web' #these three lines generate random 20 character passwords
$domain1password = [System.Web.Security.Membership]::GeneratePassword(20, 5)
$domain2password = [System.Web.Security.Membership]::GeneratePassword(20, 5)

if ($Location -eq "[[ ]]"){
    $Address = "[[ ]]"
    $city = "[[ ]]"
    $zip = "[[ ]]"
    $ofc= "[[ ]]"
    $officeemail = "[[ ]]"
    $ExtnAttrib ="1"
}

}
$useridentity= "$Fname.$Lname"

#####################################this section creates the accounts for employees#########################################
if ($orgletter -eq "L"){
    $company = "[[Company]]" 
    $org = "domain1"
    $email= "$Fname.$Lname@$org.org"
    #Creates Account with employees
    New-ADUser `
        -AccountPassword  (ConvertTo-SecureString -AsPlainText "$domain1password" -Force) -passThru `
        -ChangePasswordAtLogon $True `
        -City "$city" `
        -Company "$company" `
        -Country "US" `
        -Department "$dept" `
        -Description "$Title" `
        -DisplayName "$name" `
        -EmailAddress $email `
        -Enabled $True `
        -GivenName $Fname `
        -HomePage "www.$org.org" `
        -HomeDirectory "" `
        -HomeDrive "" `
        -Manager "CN=$Managername," `
        -Name $name `
        -Office "$Ofc" `
        -OfficePhone "$ofcphone" `
        -Path "OU=$TestOrStandard," `
        -PostalCode "$zip" `
        -SamAccountName "$Fname.$Lname" `
        -ScriptPath "" `
        -State "" `
        -StreetAddress "$Address" `
        -Surname  $Lname `
        -Title "$Title" `
        -UserPrincipalName "$Fname.$Lname@$org.com"

        Set-ADUSer -Identity $useridentity -Add @{"ipPhone" = "$ipphone"} #https://community.spiceworks.com/topic/1964765-powershell-help-set-aduser-ipphone

        if ($orgletter -like "F"){
           Set-ADUSer -Identity $useridentity -Company ""
        }

        if ($orgletter -like "M"){            
           Set-ADUSer -Identity $useridentity -Company ""
        }

    Start-Sleep -s 3 #waits 3 second to ensure that the account is created before adding groups
    
     #this section creates the new user's home folder
    New-Item -Path "[[Path]]\$Fname.$Lname" -ItemType directory
    $homedir="[[Path]]\$Fname.$Lname"
    #this grants the new user access to to new folder as per https://ss64.com/ps/set-acl.html & https://stackoverflow.com/questions/26543127/powershell-setting-advanced-ntfs-permissions
    $ACL= Get-Acl $homedir
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("[[ ]]\$Fname.$Lname","Modify",'ContainerInherit, ObjectInherit', 'None',"Allow")
    $acl.SetAccessRule($AccessRule)
    $acl | Set-Acl -Path $homedir

     Add-ADPrincipalGroupMembership $useridentity -MemberOf "Groups" # https://community.spiceworks.com/topic/2128061-powershell-adding-a-single-user-to-multiple-groups

if ($copy -like "N"){
     #Based on user input, this added the appropriate AD group for their version of Adobe Pro 
     if ($Adobe -like "S"){
        Add-ADPrincipalGroupMembership $useridentity -MemberOf "Adobe_Standard"
    }elseif ($Adobe -like "P"){
        Add-ADPrincipalGroupMembership $useridentity -MemberOf "Adobe_Pro"
    }elseif($Adobe -like "C"){
        Add-ADPrincipalGroupMembership $useridentity -MemberOf "Adobe_CreativeCloud"
    }

    if ($docusignCo -like "B"){
        Add-ADPrincipalGroupMembership $useridentity -MemberOf "", ""
    }elseif ($docusignCo -like "L"){
        Add-ADPrincipalGroupMembership $useridentity -MemberOf ""
    }elseif($docusignCo -like "C"){
        Add-ADPrincipalGroupMembership $useridentity -MemberOf ""
    }
    #this will create a domain1 branded sharefile account
    if ($sharefile -like "L"){
        Add-ADPrincipalGroupMembership $useridentity -MemberOf ""
    }elseif ($sharefile -like "C"){    #this will create a domain2 branded Sharefile account
        Add-ADPrincipalGroupMembership $useridentity -MemberOf ""
    }elseif ($sharefile -like "B"){
    #This will create both sharefile accounts
        Add-ADPrincipalGroupMembership $useridentity -MemberOf "", ""
    }

       
    #this section adds the new user to the correct ticketing AD group
        if ($TicketingGroup -eq "1"){Add-ADPrincipalGroupMembership $useridentity -MemberOf "Samanage_Admin"}
        elseif ($TicketingGroup -eq "2"){Add-ADPrincipalGroupMembership $useridentity -MemberOf "ticketinggroup1"}
        elseif ($TicketingGroup -eq "3"){Add-ADPrincipalGroupMembership $useridentity -MemberOf "ticketinggroup2"}
        elseif ($TicketingGroup -eq "4"){Add-ADPrincipalGroupMembership $useridentity -MemberOf "ticketinggroup3"}
        elseif ($TicketingGroup -eq "5"){Add-ADPrincipalGroupMembership $useridentity -MemberOf "ticketinggroup4"}
        elseif ($TicketingGroup -eq "6"){Add-ADPrincipalGroupMembership $useridentity -MemberOf "ticketinggroup5"}
        elseif ($TicketingGroup -eq "7"){Add-ADPrincipalGroupMembership $useridentity -MemberOf "ticketinggroup6"}
        elseif ($TicketingGroup -eq "8"){Add-ADPrincipalGroupMembership $useridentity -MemberOf "ticketinggroup7"}
        elseif ($TicketingGroup -eq "9"){Add-ADPrincipalGroupMembership $useridentity -MemberOf "ticketinggroup8"}
}

    #this section copies the AD group membership from an existing domain1 user to the new domain1 new user.
    if ($ADGroupsfromuser){
        $CopyFromUser = Get-ADUser $ADGroupsfromuser -prop MemberOf
        $CopyToUser = Get-ADUser $useridentity -prop MemberOf
        $CopyFromUser.MemberOf | Where-Object{$CopyToUser.MemberOf -notcontains $_} |  Add-ADGroupMember -Members $CopyToUser
    }
   
    # Set Proxyaddress Attribute in AD
    if ($dualaccount -eq "Y"){
        set-aduser -Identity $useridentity  -add @{proxyaddresses = "smtp:$($useridentity)@domain2"}
        set-aduser -Identity $useridentity  -add @{proxyaddresses = "SMTP:$($useridentity)@domain1"}
        set-aduser -Identity $useridentity  -add @{proxyaddresses = "SIP:$($useridentity)@domain1"}
    }else{ 
        set-aduser -Identity $useridentity  -add @{proxyaddresses = "SMTP:$($useridentity)@domain1"}
        set-aduser -Identity $useridentity  -add @{proxyaddresses = "SIP:$($useridentity)@domain1"}
    }
########For people who are domain1 Employees: Above this line is on the domain1 domain, below this line is on the domain2 Domain##############################

    #If domain1 user needs to have an account created on the domain2 side
    if ($dualaccount -eq "y"){
        Add-ADPrincipalGroupMembership $useridentity -MemberOf "group"
        $company=""
        $org=""
        $username="$Fname.$Lname@domain2"
        new-aduser `
        -AccountPassword (ConvertTo-SecureString -AsPlainText "$domain2password" -Force) -passThru `
        -ChangePasswordAtLogon $True `
        -City "$city" `
        -Company "$company" `
        -Country "US" `
        -Department "$dept" `
        -Description "$Title"  `
        -DisplayName "$name" `
        -EmailAddress $email `
        -Enabled $True `
        -GivenName $Fname `
        -HomePage "www.$org.org" `
        -Manager "CN=$Managername," `
        -Name $name `
        -Office "$Ofc" `
        -OfficePhone "$ofcphone" `
        -Path "OU=$TestOrStandard," `
        -PostalCode "$zip" `
        -SamAccountName "$Fname.$Lname" `
        -State "" `
        -StreetAddress "$Address" `
        -Surname $Lname `
        -Title "$Title" `
        -UserPrincipalName $username `
        -server ""

        Set-ADUSer -Identity $useridentity -server "" -Add @{"ipPhone" = "$ipphone"} #https://community.spiceworks.com/topic/1964765-powershell-help-set-aduser-ipphone

        Start-Sleep -s 3 #waits 3 second to ensure that the account is created before adding groups

        Add-ADPrincipalGroupMembership $useridentity -MemberOf "Group" -Server ""
     
    
    #this section copies the AD group membership from an existing domain2 user to the new domain2 new user.
    if ($ADGroupsfromuser){
        $CopyFromUser = Get-ADUser $ADGroupsfromuser -prop MemberOf -server ""
        $CopyToUser = Get-ADUser $useridentity -prop MemberOf -server ""
        $CopyFromUser.MemberOf | Where-Object{$CopyToUser.MemberOf -notcontains $_} |  Add-ADGroupMember -Members $CopyToUser -server ""
    }

    Get-ADUser $useridentity -Properties * -Server ""
}
################this secton is for people who are primarily domain2 employees #############################
}elseif ($orgletter -eq "C"){
    #this part creates the domain1 account for a domain2 Employee
    $company= ""
    $org = ""
    $username="$Fname.$Lname@"
    $email= "$Fname.$Lname@$org.org"
    New-ADUser `
    -AccountPassword (ConvertTo-SecureString -AsPlainText "$domain2password" -Force) -passThru `
    -ChangePasswordAtLogon $True `
    -City "$city" `
    -Company "$company" `
    -Country "US" `
    -Department "$dept" `
    -Description "$Title" `
    -DisplayName "$name" `
    -EmailAddress "$email" `
    -Enabled $True `
    -GivenName $Fname `
    -HomePage "www.$org.org" `
    -HomeDirectory "Path\$Fname.$Lname" `
    -HomeDrive "" `
    -Manager "CN=$Managername," `
    -Name $name `
    -Office "$Ofc" `
    -OfficePhone "$ofcphone" `
    -Path "OU=$TestOrStandard" `
    -PostalCode "$zip" `
    -SamAccountName "$Fname.$Lname" `
    -ScriptPath "" `
    -State "" `
    -StreetAddress "$Address" `
    -Surname $Lname `
    -Title "$Title" `
    -UserPrincipalName "$username"
	
    Set-ADUSer -Identity $useridentity -Add @{"ipPhone" = "$ipphone"} #https://community.spiceworks.com/topic/1964765-powershell-help-set-aduser-ipphone

    if ($orgletter -like "F"){
       Set-ADUSer -Identity $useridentity -Company ""
    }
    
    if ($orgletter -like "M"){            
       Set-ADUSer -Identity $useridentity -Company ""
    }

    Start-Sleep -s 3 #waits 3 second to ensure that the account is created before adding groups

    #this section creates the new user's home folder
    New-Item -Path "Path\$Fname.$Lname" -ItemType directory
    $homedir="Path\$Fname.$Lname"
    #this grants the new user access to to new folder as per https://ss64.com/ps/set-acl.html & https://stackoverflow.com/questions/26543127/powershell-setting-advanced-ntfs-permissions
    $ACL= Get-Acl $homedir
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("\$Fname.$Lname","Modify",'ContainerInherit, ObjectInherit', 'None',"Allow")
    $acl.SetAccessRule($AccessRule)
    $acl | Set-Acl -Path $homedir
    
  
    Start-Sleep -s 3 #waits 3 second to ensure that the account is created before adding groups
    # https://community.spiceworks.com/topic/2128061-powershell-adding-a-single-user-to-multiple-groups
    Add-ADPrincipalGroupMembership $useridentity -MemberOf "","","","","",""
    
    # Set Proxyaddress Attribute in AD / all domain2 users are automatically dual users with a domain1 account.
        set-aduser -Identity $useridentity  -add @{proxyaddresses = "smtp:$($useridentity)@"}
        set-aduser -Identity $useridentity  -add @{proxyaddresses = "SMTP:$($useridentity)@"}
        set-aduser -Identity $useridentity  -add @{proxyaddresses = "SIP:$($useridentity)@"}
if ($copy -like "N"){    
    #Based on user input, this added the appropriate AD group for their version of Adobe Pro
    if ($Adobe -like "S"){
        Add-ADPrincipalGroupMembership $useridentity -MemberOf "Adobe_Standard"
    }elseif ($Adobe -like "P"){
        Add-ADPrincipalGroupMembership $useridentity -MemberOf "Adobe_Pro"
    }elseif($Adobe -like "C"){
        Add-ADPrincipalGroupMembership $useridentity -MemberOf "Adobe_CreativeCloud"
    }
    #this will create a domain1 branded sharefile account
    if ($sharefile -like "L"){
        Add-ADPrincipalGroupMembership $useridentity -MemberOf ""
    }elseif ($sharefile -like "C"){
    #this will create a domain2 Branded Sharefile account.
        Add-ADPrincipalGroupMembership $useridentity -MemberOf ""
    }elseif ($sharefile -like "B"){
    #This will create both sharefile accounts
        Add-ADPrincipalGroupMembership $useridentity -MemberOf "",""
    }

    #this section adds the new user to the correct ticketing AD group
        if ($TicketingGroup -eq "1"){Add-ADPrincipalGroupMembership $useridentity -MemberOf "ticketinggroup"}
        elseif ($TicketingGroup -eq "2"){Add-ADPrincipalGroupMembership $useridentity -MemberOf "ticketinggroup1"}
        elseif ($TicketingGroup -eq "3"){Add-ADPrincipalGroupMembership $useridentity -MemberOf "ticketinggroup2"}
        elseif ($TicketingGroup -eq "4"){Add-ADPrincipalGroupMembership $useridentity -MemberOf "ticketinggroup3"}
        elseif ($TicketingGroup -eq "5"){Add-ADPrincipalGroupMembership $useridentity -MemberOf "ticketinggroup4"}
        elseif ($TicketingGroup -eq "6"){Add-ADPrincipalGroupMembership $useridentity -MemberOf "ticketinggroup5"}
        elseif ($TicketingGroup -eq "7"){Add-ADPrincipalGroupMembership $useridentity -MemberOf "ticketinggroup6"}
        elseif ($TicketingGroup -eq "8"){Add-ADPrincipalGroupMembership $useridentity -MemberOf "ticketinggroup7"}
        elseif ($TicketingGroup -eq "9"){Add-ADPrincipalGroupMembership $useridentity -MemberOf "ticketinggroup8"}
}
    #this section copies the AD group membership from an existing domain1 user to the new domain1 new user.
    if ($ADGroupsfromuser){
        $CopyFromUser = Get-ADUser $ADGroupsfromuser -prop MemberOf
        $CopyToUser = Get-ADUser $useridentity -prop MemberOf
        $CopyFromUser.MemberOf | Where-Object{$CopyToUser.MemberOf -notcontains $_} |  Add-ADGroupMember -Members $CopyToUser
    }

###############For Peoeple who are primarily domain2 employees only:  Above this line is on the domain1 domain, below this line is on the domain2 Domain####################################
    #this part creates the domain2 account for a domain2 Employee
    new-aduser `
    -AccountPassword (ConvertTo-SecureString -AsPlainText "$domain2password" -Force) -passThru `
    -ChangePasswordAtLogon $True `
    -City "$city" `
    -Company "$company" `
    -Country "US" `
    -Department "$dept" `
    -Description "$Title" `
    -DisplayName "$name" `
    -EmailAddress "$email" `
    -Enabled $True `
    -GivenName $Fname `
    -HomePage "www.$org.org" `
    -Manager "CN=$Managername," `
    -Name $name `
    -Office "$Ofc" `
    -OfficePhone "$ofcphone" `
    -Path "OU=$TestOrStandard," `
    -PostalCode "$zip" `
    -SamAccountName "$Fname.$Lname" `
    -State "" `
    -StreetAddress "$Address" `
    -Surname $Lname `
    -Title "$Title" `
    -UserPrincipalName "$username" `
    -server ""

    Set-ADUSer -Identity "$Fname.$Lname" -server "" -Add @{"ipPhone" = "$ipphone"} #https://community.spiceworks.com/topic/1964765-powershell-help-set-aduser-ipphone

    Start-Sleep -s 3 #waits 3 second to ensure that the account is created before adding groups

    Add-ADPrincipalGroupMembership $useridentity -MemberOf "" -Server ""

    #this section copies the AD group membership from an existing domain2 user to the new domain2 new user.
    if ($ADGroupsfromuser){
        $CopyFromUser = Get-ADUser $ADGroupsfromuser -prop MemberOf -server ""
        $CopyToUser = Get-ADUser $useridentity -prop MemberOf -server ""
        $CopyFromUser.MemberOf | Where-Object{$CopyToUser.MemberOf -notcontains $_} |  Add-ADGroupMember -Members $CopyToUser -server ""
    }
    Get-ADUser $useridentity -Properties * -Server ""
}
}else{
    Write-Host "Invalid employer selection"
}

Get-ADUser $useridentity -Properties * 