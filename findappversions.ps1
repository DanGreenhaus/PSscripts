<#  
.SYNOPSIS  
    Returns installed application information based on information in add/remove programs.
.DESCRIPTION  
    Ths script can search one computer or multiple computers for installed applications.  It's primary use case is to locate vulnerable versions of software, 
    particularly when they have been installed on an individual user's profile.  This is designed to be ran on a user's local machine; to get all the results, the user will need to be an 
    admin on the destination computer.
.NOTES  
    File Name  : FindAppVersions.ps1  
    Author     : Dan Greenhaus
    Requires   : PowerShell 5.x, preferable Powershell 7  
    Date       : 6/3/2022
.LINK #>
$servers = Get-Content #<--insert txt or csv with endpoints listed here
$AppName = "google" #<---enter name of the application or publisher here
ForEach($server in $servers) {
 #If only running on a single endpoint, add the following line: $server= <hostname>
    #ping the server to ensure that it's online, and return it's IP address
    Test-Connection $server -Count 1 -ResolveDestination | Select-Object Destination, Address, status #this section only works if you are running Powershell 7
    Write-Host "processing workstation $server"
  invoke-command -ComputerName $server -ScriptBlock {
  #if running on a local machine, just run this block
    #These two lines search for machine wide installations
    $InstalledSoftware = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
    foreach($obj in $InstalledSoftware){
        if ($obj.GetValue('DisplayName') -like "*$AppName*") {write-host $obj.GetValue('DisplayName') -NoNewline; write-host " - Version " `
         -NoNewline; write-host $obj.GetValue('DisplayVersion')-nonewline; write-host " - Uninstall path: "  -NoNewline;Write-Host $obj.GetValue('UninstallString')}
    }
    $wow6432=Get-ChildItem "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    foreach($obj in $wow6432){
        if ($obj.GetValue('DisplayName') -like "*$AppName*") {write-host $obj.GetValue('DisplayName') -NoNewline; write-host " - Version " `
          -NoNewline; write-host $obj.GetValue('DisplayVersion')-nonewline; write-host " - Uninstall path: "  -NoNewline;Write-Host $obj.GetValue('UninstallString')}
    }
    #these lines search of applications that are installed in individual user's profiles
    $HKU= Get-ChildItem "Registry::HKEY_USERS\*\Software\Microsoft\Windows\CurrentVersion\Uninstall" -Recurse
    foreach($obj in $HKU){
      if ($obj.GetValue('DisplayName') -like "$AppName*") {write-host $obj.GetValue('DisplayName') -NoNewline; write-host " - Version" `
        -NoNewline; write-host $obj.GetValue('DisplayVersion') -nonewline; write-host " - Installation path: "  -NoNewline;Write-Host $obj.GetValue('UninstallString')}
    }
    $HKUwow= Get-ChildItem "Registry::HKEY_USERS\*\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -Recurse
    foreach($obj in $HKUwow){
      if ($obj.GetValue('DisplayName') -like "$AppName*") {write-host $obj.GetValue('DisplayName') -NoNewline; write-host " - Version" `
        -NoNewline; write-host $obj.GetValue('DisplayVersion') -nonewline; write-host " - Installation path: "  -NoNewline;Write-Host $obj.GetValue('UninstallString')}
    }
  }
}