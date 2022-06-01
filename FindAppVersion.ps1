$servers = Get-Content <insert file name and path here>
ForEach($server in $servers) {
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
  }
}
