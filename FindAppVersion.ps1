$servers = Get-Content <insert file name and path here> 
ForEach($server in $servers) {
 #If only running on a single endpoint, add the following line: $server= <hostname>
  Test-Connection $server -Count 1 -ResolveDestination | Select-Object Destination, Address, status #this section only works if you are running Powershell 7
    Write-Host "processing workstation $server"
  invoke-command -ComputerName $server -ScriptBlock {
    $InstalledSoftware = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
    foreach($obj in $InstalledSoftware){
        if ($obj.GetValue('DisplayName') -like "*Chrome*") {write-host $obj.GetValue('DisplayName') -NoNewline; write-host " - " -NoNewline; write-host $obj.GetValue('DisplayVersion')}
    }
    $wow6432=Get-ChildItem "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    foreach($obj in $wow6432){
        if ($obj.GetValue('DisplayName') -like "*Chrome*") {write-host $obj.GetValue('DisplayName') -NoNewline; write-host " - " -NoNewline; write-host $obj.GetValue('DisplayVersion')}
    }
    $HKU= Get-ChildItem "Registry::HKEY_USERS\*\Software\Microsoft\Windows\CurrentVersion\Uninstall" -Recurse
    foreach($obj in $HKU){
      if ($obj.GetValue('DisplayName') -like "*Chrome*") {write-host $obj.GetValue('DisplayName') -NoNewline; write-host " - " -NoNewline; write-host $obj.GetValue('DisplayVersion') -nonewline; write-host " - "  -NoNewline;Write-Host $obj.GetValue('UninstallString'); write-host $obj.GetValue('DisplayVersion') -nonewline; write-host " - "  -NoNewline;Write-Host $obj.GetValue('UninstallString') }
    }
    $HKUwow= Get-ChildItem "Registry::HKEY_USERS\*\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -Recurse
    foreach($obj in $HKUwow){
      if ($obj.GetValue('DisplayName') -like "*Chrome*") {write-host $obj.GetValue('DisplayName') -NoNewline; write-host " - " -NoNewline; write-host $obj.GetValue('DisplayVersion') -nonewline; write-host " - "  -NoNewline;Write-Host $obj.GetValue('UninstallString'); write-host $obj.GetValue('DisplayVersion') -nonewline; write-host " - "  -NoNewline;Write-Host $obj.GetValue('UninstallString')}
    }
  }
}
