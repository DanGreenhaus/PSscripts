#call the PS from a windows shortcut using the following :powershell.exe -NoExit -ExecutionPolicy Bypass -File "<path and filename>"
$perfmonRunning = Get-Process -Name perfmon -ErrorAction SilentlyContinue
$mmcRunning = Get-Process -Name mmc -ErrorAction SilentlyContinue
if ($perfmonRunning -or $mmcRunning) { Write-Host "Performance Monitor is already running." } 
else { Write-Host "Starting Performance Monitor..."
 Invoke-Item "$env:SystemRoot\system32\perfmon.exe" }

# Wait for space bar press
Write-Host "Press the space bar to exit..."
do {
    $key = [System.Console]::ReadKey($true)
} while ($key.Key -ne 'Spacebar')