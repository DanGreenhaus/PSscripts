#https://4sysops.com/archives/find-and-remove-duplicate-files-with-powershell/
# Define source directory
$srcDir = "D:\Profile Data File Storage\Dan\Pictures\comics"
# Define destination directory
$targetDir = "D:\Temp\DuplicateFiles\$(Get-Date -Format 'yyyyMMdd')"
# Create destination directory 
if(!(Test-Path -PathType Container $targetDir)){ New-Item -ItemType Directory -Path $targetDir | Out-Null }
# Manually choose duplicate files to move to target directory
$exportlocation= "D:\temp\DuplicateFiles\DupeFileList" + (Get-Date -Format 'yyyyMMdd')+ ".csv"
Get-ChildItem -Path $srcDir -File -Recurse | Group-Object -Property Length |
    Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Group |
    Get-FileHash | Group-Object -Property Hash | Where-Object { $_.count -gt 1 } | ForEach-Object { $_.Group |
    Select-Object Path, Hash | Export-Csv -path $exportlocation -Append -NoTypeInformation} |
    Out-GridView -Title "Select the file(s) to move to `"$targetDir`" directory." -PassThru |
    Move-Item -Destination $targetDir -Force -Verbose