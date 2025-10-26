powershell.exe -ExecutionPolicy Bypass -Command {
$perfmonRunning = Get-Process -Name perfmon -ErrorAction SilentlyContinue
$mmcRunning = Get-Process -Name mmc -ErrorAction SilentlyContinue

if ($perfmonRunning -or $mmcRunning) { Write-Host "Performance Monitor is already running." } 
else { Write-Host "Starting Performance Monitor..." Start-Process perfmon.exe }

Write-Host "Press the space bar to exit..."
do {
    $key = [System.Console]::ReadKey($true)
} while ($key.Key -ne 'Spacebar')

}