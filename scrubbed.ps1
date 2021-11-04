<#  
.SYNOPSIS  
    Automates many of the pre-application-install and post-application-install processes needed to upgrade the APP Application 
.DESCRIPTION  
    This script is divided into two halves: the top half that is run in the test/lower tier enviornment, and the bottom half that is run on the production enviornment.  
    Each half is then divided into two sections: Pre-app install and post app install.  Each Section is divided into 5 functions: VM related snapshots, monitoring,
    services & IIS, SMB fileshares, and the Web.config file.
    
    All these sections should be run from APP-TST-UTIL-01.cu.core, from an elevated command prompt using your admin credentials.   If you attempt to run the VMware 
    section or monitoring from a different computer or as a different user using the provided credential file, IT WILL NOT WORK. you will need to recreate the 
    credential file on the computer and using the admin credentials for the user that will be running the script.  Also, if you have changed your password, in accordance
    with our password policy, since you last created the CRED file, you will need to update the CRED file with your new credentials.

    Do NOT simply run this powershell script; Follow the directions in APP Upgrade Checklist.docx and run the appropriate section when indicated.

.NOTES  
    File Name  : APP Patching Commands.ps1  
    Author     : Dan Greenhaus
    Date       : 12/28/2020

.Example
    Do NOT run this powershell script from the PS Commandline; Follow the directions in APP Upgrade Checklist.docx and run the appropriate section when indicated.

.link
    Sharepoint links to the directions
#>

#This section is required for taking snapshots of the servers in both Test and Prod
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Import-Module VMware.VimAutomation.Core -Force #downloaded from https://www.powershellgallery.com/packages/VMware.VimAutomation.Core/12.1.0.16997984
$Credential = Import-CliXml -path C:\Users\Dan\Documents\DanAdmin.Cred #note: this line only works for Dan's credentials, when logged in on the APP-Util server
# Credentials
$vcserver = "VMWareServer”
$vcusername = $Credential.UserName
# Login VMware
Connect-VIServer -Server $vcserver -Protocol https -User $vcusername -Password $Credential.GetNetworkCredential().Password

#For APPTest run this block
# VM information
$APPTestAppVMs="Test-App-01_restored09_03","Test-App-02_restored09_03","test-API_Server_1” #reminder: these are the VM names from vsphere, not the server names
# Take Snapshot
ForEach ($VM in $TESTAppServers){
        $snapshotname = $vm + "-backup"
        write-host "Creating snapshot [$snapshotname] for the VM [$vm]"
        New-Snapshot -vm $vm -name $snapshotname -confirm:$false -runasync:$true
}

#sets affected servers into maintenance mode
$APPTestSurroundingServers="test-FileTransfer-01","test-appconnect","test-appcon-2"."Test-App-01","Test-App-02","test-API_Server_1-01"
ForEach ($server in  $APPTestSurroundingServers){
    C:\Scripts\set_solarwinds_unmanaged.ps1 -hostname $server -server "SolarWindsServer" -credstore C:\Users\Dan\Documents\DanAdmin.Cred -action unmanage -minutes 60
}

#stops services on associated servers.  This might take a minute or two; just be patient
Invoke-Command -ComputerName "test-FileTransfer-01" -ScriptBlock {
    Stop-Service "FILEAWTRANSFER-TEST" 
}

Invoke-Command -ComputerName "test-appconnect" -ScriptBlock {
    Stop-Service CMCService 
    Stop-Service PezService 
}

Invoke-Command -ComputerName "test-AppConnector-2" -ScriptBlock {
    Stop-Service CMCService 
    Stop-Service PezService 
}
<#since we don't have multipoint or CRM in test, skip this section
Invoke-Command -ComputerName multipoint -ScriptBlock {
    Stop-Service MPI41 #display name is Corilian Multipoint Integrator 4.1 
}

Invoke-Command -ComputerName "CRM-PRD-01" -ScriptBlock {
    Stop-Service "Activity Manager" 
    Stop-Service "cView Scheduler"
    Stop-Service "cViewMapPointService"
    IISreset /stop
}
#>

Invoke-Command -ComputerName "test-LoanOriginations-ps" -scriptblock {
    IISreset /stop
}

Invoke-Command -ComputerName "test-LoanOriginations-svc" -scriptblock {
    IISreset /stop
    Stop-Service "Consumer-OriginationPrintService - Test-SVC"  
    Stop-Service "PrintServiceProxyHost - Test-SVC"  
    Stop-Service "Consumer-OriginationInterfacesQueueService - Test-SVC"  
    Stop-Service "IAScheduleEngineWindowsService - Test-SVC"  
    Stop-Service "Consumer-OriginationWebServiceEngine - Test-SVC"  
}

Get-SmbOpenFile -CimSession CoreApps-FileServer | Where-Object Path -like "E:\APP\TEST\*" | Close-SmbOpenFile -Force #to close open files in a share
#Get-SmbOpenFile -CimSession CoreApps-FileServer | Where-Object Path -like "E:\APP\DEV\*" | Close-SmbOpenFile -Force #to close open files in a share if updating DEV
#Get-SmbOpenFile -CimSession CoreApps-FileServer | Where-Object Path -like "E:\APP\STAT\*" | Close-SmbOpenFile -Force #to close open files in a share if updating STAT
#Get-SmbOpenFile -CimSession CoreApps-FileServer | Where-Object Path -like "E:\APP\TRAIN\*" | Close-SmbOpenFile -Force #to close open files in a share if updating TRAIN

#to restart all the services and re-enable monitoring
$APPTestSurroundingServers="test-FileTransfer-01","test-appconnect","test-appcon-2",<#"multipoint","CRM-PRD-01",#>"Test-App-01","Test-App-02","test-API_Server_1-01"
ForEach ($server in  $APPTestSurroundingServers){
    C:\Scripts\set_solarwinds_unmanaged.ps1 -hostname $server -server SolarWindsServer -credstore C:\Users\Dan\Documents\DanAdmin.Cred -action remanage
}

Invoke-Command -ComputerName "test-FileTransfer-01" -ScriptBlock {
    Start-Service "FILEAWTRANSFER-TEST" 
}

Invoke-Command -ComputerName "test-appconnect" -ScriptBlock {
    Start-Service CMCService 
    Start-Service PezService
}

Invoke-Command -ComputerName "test-AppConnector-2" -ScriptBlock {
    Start-Service CMCService 
    Start-Service PezService
}
<#since we don't have multipoint or CRM in test, skip this section
Invoke-Command -ComputerName "multipoint" -ScriptBlock {
    Start-Service MPI41 #display name is Corilian Multipoint Integrator 4.1 
}

Invoke-Command -ComputerName "CRM-PRD-01" -ScriptBlock {
    Start-Service "Activity Manager" 
    Start-Service "cView Scheduler"
    Start-Service "cViewMapPointService"
    IISreset /start
    
}#>

Invoke-Command -ComputerName "test-LoanOriginations-ps" -scriptblock {
    IISreset /start
}

Invoke-Command -ComputerName "test-LoanOriginations-svc" -scriptblock {
    IISreset /start
    start-Service "Consumer-OriginationPrintService - Test-SVC"  
    start-Service "PrintServiceProxyHost - Test-SVC"  
    start-Service "Consumer-OriginationInterfacesQueueService - Test-SVC"  
    start-Service "IAScheduleEngineWindowsService - Test-SVC"  
    start-Service "Consumer-OriginationWebServiceEngine - Test-SVC"  
}

# Remove Snapshot
ForEach ($VM in  $APPTestAppVMs){
    $snapshotname = $vm + "-backup"
    $snap = get-Snapshot -vm $vm -name $snapshotname
    write-host "Removing snapshot [$snapshotname] for the VM [$vm]"
    remove-snapshot -snapshot $snap -confirm:$false -runasync:$true
}
#################################################End of TEST section #########################################################

#For APP Prod run this block
# VM information
$APPappVMs="APP_SERVER_01","App_Server_02","App_Server_DisasterRecovery_01","App_Server_DisasterRecovery_02","Api_Server_02","Api_Server_01","Api_Server_DisasterRecovery_02","Api_Server_DisasterRecovery_01"
# Take Snapshots
ForEach ($VM in  $APPappVMs){
        $snapshotname = $vm + "-backup"
        write-host "Creating snapshot [$snapshotname] for the VM [$vm]"
        New-Snapshot -vm $vm -name $snapshotname -confirm:$false -runasync:$true
}
#to disable monitoring on all the prod APP servers
$APPProdServers="FileTransfer-01","core-AppConnector","core-AppConnectoror-2","multipoint","CRM-PRD-01","APP_SERVER_01","App_Server_02","Api_Server_01","Api_Server_02","Api_Server_DisasterRecovery_01","Api_Server_DisasterRecovery_02","App_Server_DisasterRecovery_01","App_Server_DisasterRecovery_02","Consumer-Origination-ps","Consumer-Origination-svc"
ForEach ($server in  $APPProdServers){
    C:\Scripts\set_solarwinds_unmanaged.ps1 -hostname $server -server SolarWindsServer -credstore C:\Users\Dan\Documents\DanAdmin.Cred -action unmanage -minutes 240
}

#copies the web.config to the user's deskstop, which will be needed after the update
$APPsafServers="APP_SERVER_01","APP_SERVER_02","APP_SERVER_DISASTERRECOVERY_01","APP_SERVER_DISASTERRECOVERY_02"
ForEach ($server in  $APPsafServers){
    Invoke-Command -ComputerName $server -ScriptBlock {
        $destpath="$env:userprofile"+"\desktop"
        Copy-Item -path "C:\Program Files\Company Name\Prod-APP Website\CoreObjectDirector\web.config" -destination $destpath
    }
}

#stops services on associated servers This might take a minute or two; just be patient
Invoke-Command -ComputerName "FileTransfer-01" -ScriptBlock {
    Stop-Service "FILEAWTRANSFER-PROD" 
}

Invoke-Command -ComputerName "core-AppConnector" -ScriptBlock {
    Stop-Service CMCService 
    Stop-Service PezService 
}

Invoke-Command -ComputerName "core-AppConnectoror-2" -ScriptBlock {
    Stop-Service CMCService 
    Stop-Service PezService 
}

Invoke-Command -ComputerName "multipoint" -ScriptBlock {
    Stop-Service MPI41   #display name is Corilian Multipoint Integrator 4.1 
}

Invoke-Command -ComputerName "CRM-PRD-01" -ScriptBlock {
    Stop-Service "Activity Manager"  
    Stop-Service "cView Scheduler" 
    Stop-Service "cViewMapPointService" 
    IISreset /stop
}

Get-SmbOpenFile -CimSession "CoreApps-FileServer" | Where-Object Path -like "E:\APP\Prod\*" | Close-SmbOpenFile -Force #to close open files in a share

Invoke-Command -ComputerName "Consumer-Origination-ps" -scriptblock {
    IISreset /stop
}

Invoke-Command -ComputerName "Consumer-Origination-svc" -scriptblock {
    IISreset /stop
    Stop-Service "Consumer-OriginationPrintService - Prod-SVC"  
    Stop-Service "PrintServiceProxyHost - Prod-SVC"  
    Stop-Service "Consumer-OriginationInterfacesQueueService - Prod-SVC"  
    Stop-Service "IAScheduleEngineWindowsService - Prod-SVC"  
    Stop-Service "Consumer-OriginationWebServiceEngine - Prod-SVC"  
}
#to restart all the services and re-enable monitoring
$APPProdServers="FileTransfer-01","core-AppConnector","core-AppConnectoror-2","multipoint","CRM-PRD-01","APP_SERVER_01","App_Server_02","Api_Server_01","Api_Server_02","Api_Server_DisasterRecovery_01","Api_Server_DisasterRecovery_02","App_Server_DisasterRecovery_01","App_Server_DisasterRecovery_02","Consumer-Origination-ps","Consumer-Origination-svc"
ForEach ($server in  $APPProdServers){
    C:\Scripts\set_solarwinds_unmanaged.ps1 -hostname $server -server SolarWindsServer -credstore C:\Users\Dan\Documents\DanAdmin.Cred -action remanage
}

Invoke-Command -ComputerName "FileTransfer-01" -ScriptBlock {
    Start-Service "FILEAWTRANSFER-PROD" 
}

Invoke-Command -ComputerName "core-AppConnector" -ScriptBlock {
    Start-Service CMCService 
    Start-Service PezService
}

Invoke-Command -ComputerName "core-AppConnectoror-2" -ScriptBlock {
    Start-Service CMCService 
    Start-Service PezService
}

Invoke-Command -ComputerName "multipoint" -ScriptBlock {
    Start-Service MPI41 #display name is Corilian Multipoint Integrator 4.1 
}

Invoke-Command -ComputerName "CRM-PRD-01" -ScriptBlock {
    Start-Service "Activity Manager" 
    Start-Service "cView Scheduler"
    Start-Service "cViewMapPointService"
    IISreset /start
}

Invoke-Command -ComputerName "Consumer-Origination-ps" -scriptblock {
    IISreset /start
}

Invoke-Command -ComputerName "Consumer-Origination-svc" -scriptblock {
    IISreset /start
    start-Service "Consumer-OriginationPrintService - Prod-SVC"  
    start-Service "PrintServiceProxyHost - Prod-SVC"  
    start-Service "Consumer-OriginationInterfacesQueueService - Prod-SVC"  
    start-Service "IAScheduleEngineWindowsService - Prod-SVC"  
    start-Service "Consumer-OriginationWebServiceEngine - Prod-SVC"  
}

#change the web.config file after the upgrade  - still a work in progress
$APPsafServers="APP_SERVER_01","APP_SERVER_02","APP_SERVER_DISASTERRECOVERY_01","APP_SERVER_DISASTERRECOVERY_02"
ForEach ($server in  $APPsafServers){
    Invoke-Command -ComputerName $server -ScriptBlock {
        $destpath="$env:userprofile"+"\desktop"
        $NewWebConfig= "C:\Program Files\Company Name\Prod-APP Website\CoreObjectDirector\web.config"
        $oldline = Get-Content $destpath\web.config | Select-String "CORE.CCProcessor" | Select-Object -ExpandProperty Line
        $newline = Get-Content $NewWebConfig | Select-String "CORE.CCProcessor" | Select-Object -ExpandProperty Line
        $content = Get-Content $NewWebConfig | ForEach-Object {$_ -replace 'maxArrayLength="1048576"','maxArrayLength="2097152"'} 
        $content | ForEach-Object {$_ -replace $newline,$oldline} | Set-Content $NewWebConfig
        Remove-item $destpath\web.config
    }
}
#perform IISresets on the SAF and API servers
$APPsafServers="APP_SERVER_01","App_Server_02","App_Server_DisasterRecovery_01","App_Server_DisasterRecovery_02"
ForEach ($server in  $APPsafServers){
    write-host "Connecting to" $server
    Invoke-Command -ComputerName $server -ScriptBlock { IISReset }
}

$APPapiServers="API_SERVER_01","API_SERVER_02","Api_Server_DisasterRecovery_01","Api_Server_DisasterRecovery_02"
ForEach ($server in  $APPapiServers){
    write-host "Connecting to" $server
    Invoke-Command -ComputerName $server -ScriptBlock { IISReset }
}

# Remove Snapshot
ForEach ($VM in  $APPProdServers){
    $snapshotname = $vm + "-backup"
    $snap = get-Snapshot -vm $vm -name $snapshotname
    write-host "Removing snapshot [$snapshotname] for the VM [$vm]"
    remove-snapshot -snapshot $snap -confirm:$false -runasync:$true
}
