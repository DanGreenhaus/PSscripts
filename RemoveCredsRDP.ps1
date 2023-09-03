<#
        .SYNOPSIS
        This script will take an existing .RDG file, strip out any saved credentials and save it as a new file.

        .DESCRIPTION
        Any one who works with multiple servers will use Window's Remove Desktop Connection Manager, and have a .rdg file with all of their servers.  However
        when a new person joins their team, they often have to build their own, because RDG saves credentials to make things eaiser, but lacks an easy way
        to remove the saved credentials.  This script will prompt the user for the path and file name, and then remove all saved credentials, saving the new
        file in the same directory as the current file. 

        .PARAMETER Name
        NONE
        
        .INPUTS
        None. You cannot pipe objects to Add-Extension.

        .OUTPUTS
        the script will generate a new file, as well as output the location of the file

        .EXAMPLE
        PS> RemoveCredsRDP.ps1
        Where is your RDP file located? Please enter the file path: 
        What is the filename of your .rdg file:
        The newly created file, without any saved credentials, can be found at Credential-less_<filename>.rdg

        .LINK
        Online version: https://github.com/DanGreenhaus/PSscripts
    #>

$path = Read-Host("Where is your RDP file located? Please enter the file path")
$file = Read-Host("What is the filename of your .rdg file")

#a similar regex syntax was found at https://community.spiceworks.com/topic/2249476-extract-text-between-two-keywords-in-powershell
(Get-Content -Raw $path\$file) -replace "(?sm)<credentialsProfile.*?(?=</credentialsProfile>)", '' |`
  ForEach-Object {$_ -replace " </credentialsProfile>",""} |
    ForEach-Object {$_ -replace "</credentialsProfiles>",""} |Set-Content $path\Credential-less_$file

(Get-Content -Raw $path\Credential-less_$file) -replace "(?sm)<logonCredentials.*?(?=</logonCredentials>)", '' |`
  ForEach-Object {$_ -replace "</logonCredentials>",""} | Set-Content $path\Credential-less_$file
Write-Host ("The newly created file, without any saved credentials, can be found at $path\Credential-less_$file")
