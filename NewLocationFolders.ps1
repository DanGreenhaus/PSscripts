#################                          New Site Folder Setup                       #################
#                                                                                                        # 
# Usage:                                                                                                 #
# .\New_Site_FolderSetup.ps1 -NewSite "new Site" -NewDist "District"                                     #
#                                                                                                        # 
# Creates AD Groups and folders and assigns rights to the folders based upon an existing Site's          #
# folders.                                                                                               #
#                                                                                                        # 
#  - New Site is the name of the folder to be created. ie: "286-Angier"                                  #
#  - District is the district folder the Site folder should exist in. ie: "District 31"                  # 
#                                                                                                        # 
#  Powershell NTFS modules must be installed for this script to work.                                    # 
#    https://gallery.technet.microsoft.com/scriptcenter/1abd77a5-9c0b-4a2b-acef-90dbb2b84e85             #
#  And Quest ActiveRoles management module:                                                              #
#    http://www.powershelladmin.com/wiki/Quest_ActiveRoles_Management_Shell_Download                     #
#                                                                                                        #
##########################################################################################################

# get input parameters
Param ( 
 [Parameter(Mandatory=$true)]
 [String]$NewSite,
 
 [Parameter(Mandatory=$true)]
 [String]$NewDist
)

"Creating $NewSite"

# check if modules are installed and are the correct versions
Add-PSSnapin Quest.ActiveRoles.ADManagement
Import-Module NTFSSecurity
if(get-module NTFSSecurity){ 
 if ([int](((get-module NTFSSecurity).Version.Major).tostring() + ((get-module NTFSSecurity).Version.Minor).tostring() + ((get-module NTFSSecurity).Version.build).tostring()) -lt 423){Install-Module NTFSSecurity}
} else {
 Install-Module NTFSSecurity
}

$HomeDirectoryAdmin="HomeDirectory Admins"
$OldSite="Templatefolders"
$OldSiteNumber=$OldSite.split("-")[0] # get the template number from the template name
$NewSiteNumber=$NewSite.split("-")[0] # get the new Site number from the new Site name

$DistrictManagerGroup="DM-" + $NewDist.split(" ")[1]# get the New District Manager group from the district name


## Check if groups exist, if they don't create them
$NewSiteAdminGroup="SA-$NewSiteNumber" # Site Admin group
$NewSiteMangerGroup="SM-$NewSiteNumber" # Site Manager Group 
$NewHomeDirectoryGroup="homedirprod_SA_$NewSiteNumber" # Site Admin group for district homedir.

try {Get-AdGroup $DistrictManagerGroup} catch {
 New-ADGroup -GroupScope Universal -Name $DistrictManagerGroup -path "<DM Group OU>" -Description "District Manager Group for $NewDist" -DisplayName $DistrictManagerGroup
}

try {Get-AdGroup $NewSite} catch {
 New-ADGroup -GroupScope Universal -Name $NewSite -path "<New Site OU>" -Description "Site Group for Site $NewSite" -DisplayName $NewSite
}

try {Get-ADGroup $NewSiteAdminGroup} catch {
 New-ADGroup -GroupScope Universal -Name $NewSiteAdminGroup -path "<Site Admin OU>" -Description "Site Admin Group for Site $NewSiteNumber" -DisplayName $NewSiteAdminGroup
}
 
try {Get-ADGroup $NewSiteMangerGroup} catch {
 New-ADGroup -GroupScope Universal -Name $NewSiteMangerGroup -Path "<Site Manager OU>" -Description "Site Manger Group for Site $NewSiteNumber" -DisplayName $NewSiteMangerGroup
}

try {Get-ADGroup $NewHomeDirectoryGroup} catch {
 $ManagedBy="Support Center OU"
 New-ADGroup -GroupScope Universal -Name $NewHomeDirectoryGroup -Path "<NEW AD Group OU>" -Description "" -DisplayName $NewHomeDirectoryGroup -ManagedBy ($ManagedBy)
 $ActiveDirectoryOU=get-adgroup $NewHomeDirectoryGroup | Select-Object DistinguishedName
 Add-ADGroupMember -Identity $NewHomeDirectoryGroup -Members $NewSiteAdminGroup # add Site Admin grpup
 "Groups Created Waiting 20 Seconds for AD sync."
 "Check $NewHomeDirectoryGroup and confirm that $NewSiteAdminGroup is a member of the group and that the check box is checked on Managed By after script completion"
 Start-Sleep -s 20
 Add-QADPermission $ActiveDirectoryOU.DistinguishedName -Account $ManagedBy -rights 'ReadProperty,WriteProperty' -property "member" -ApplyToType 'group' # give support center manager rights on group
}


## Groups Created now Create Folders

$Folderpath="districts\" # Districts folder path
$OldDistrict=$Folderpath +"District 88 - Testing"
$NewDistrictPath="$Folderpath$NewDist" # district path from input district
$OldSitePath=$OldDistrict + "\" + $OldSite + "\" # existing Site folder path
$NewSitePath=$NewDistrictPath + "\" + $NewSite + "\" # new Site folder path
if(-not(Test-Path "$NewSitePath")) { # create new Site folder if it doesn't exist
 mkdir "$NewSitePath"
 Set-NTFSOwner -Account $HomeDirectoryAdmin -PassThru -Path $NewSitePath
 Add-NTFSAccess -AccessRights FullControl -Account $HomeDirectoryAdmin -Path $NewSitePath
 Disable-NTFSAccessInheritance -Path "$NewSitePath" -RemoveInheritedAccessRules
}

## Create Site Scanned Docs folder
$SiteScannedDocs=$Folderpath + "SiteScannedDocuments\" + $NewSiteNumber
if(-not (Test-path $SiteScannedDocs)) {
 mkdir "$SiteScannedDocs\MFD Scans"
 Set-NTFSOwner -Account $HomeDirectoryAdmin -PassThru -Path $SiteScannedDocs
 Add-NTFSAccess -AccessRights FullControl -Account $HomeDirectoryAdmin -Path $SiteScannedDocs
 Disable-NTFSAccessInheritance -Path "$SiteScannedDocs" -RemoveInheritedAccessRules
 Add-NTFSAccess -AccessRights FullControl -Account $DistrictManagerGroup -Path $SiteScannedDocs
 Add-NTFSAccess -AccessRights FullControl -Account $NewSite -Path $SiteScannedDocs
 Add-NTFSAccess -AccessRights FullControl -Account "Sitescanneddocuments_rw" -Path $SiteScannedDocs
 Remove-NTFSAccess -AccessRights ChangePermissions, TakeOwnership -Account $DistrictManagerGroup -Path $SiteScannedDocs
 Remove-NTFSAccess -AccessRights ChangePermissions, TakeOwnership -Account $NewSite -Path $SiteScannedDocs
 Remove-NTFSAccess -AccessRights ChangePermissions, TakeOwnership -Account "Sitescanneddocuments_rw" -Path $SiteScannedDocs
}

$folders=@() # empty array for folders
$folders+=$OldSitePath  # add root folder for existing Site
$folders+=cmd /c dir /ad /b /c /on "$OldSitePath" # get existing Site subfolders

foreach ($folder in $folders){ # parse array folder by folder
 if (-not($folder -eq $OldSitePath)) { # if it is not parent folder
  $NewFolder=$folder.Replace($OldSiteNumber,$NewSiteNumber) # change the Site number on subfolder
  $NewSiteFolders="$NewSitePath$NewFolder" # new subfolder path
  if(-not(Test-Path "$NewSiteFolders")) { # if the new subfolder doesn't exist
   mkdir "$NewSiteFolders" # create it
   Set-NTFSOwner -Account $HomeDirectoryAdmin -PassThru -Path $NewSiteFolders
   Add-NTFSAccess -AccessRights FullControl -Account $HomeDirectoryAdmin -Path $NewSiteFolders
   Disable-NTFSAccessInheritance -Path "$NewSiteFolders" -RemoveInheritedAccessRules
   if($NewSiteFolders -like "*Site Administration*"){mkdir "$NewSiteFolders\modules"}
   $OldSiteSubFolders="$OldSitePath$folder" # existing Site subfolder
   $OldSiteAccessControlLists=get-acl $OldSiteSubFolders | ForEach-Object { $_.access } |Select-Object IdentityReference, FileSystemRights # get the acls for the subfolder
  }
 } else {  # if it is the Site parent folder
  $OldSiteAccessControlLists=get-acl $OldSitePath | ForEach-Object { $_.access } |Select-Object IdentityReference, FileSystemRights # get the acls for the folder
  $NewSiteFolders=$NewSitePath # set the folder to the new Site parent
 }

 Foreach ($OldSiteAccessControlList in $OldSiteAccessControlLists){  # parse the ACLs for the existing folder
  $NewSiteID=$OldSiteAccessControlList | ForEach-Object {(($_.identityreference -replace $OldSite, $NewSite) -Replace $OldSiteNumber,$NewSiteNumber) -replace "DM-88",$DistrictManagerGroup} # change the Site name and number of the acl
  $NewSiteAccess=$OldSiteAccessControlList.FileSystemRights # get the assigned file system rights to the existing folder
  Add-NTFSAccess -Path $NewSiteFolders -Account $NewSiteID -AccessRights $NewSiteAccess # apply those rights to the newly created folder
 }
 Set-NTFSOwner -Account $HomeDirectoryAdmin -PassThru -Path $NewSiteFolders
}
