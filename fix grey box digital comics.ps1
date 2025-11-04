# This script will take those grey box comics in .cbr format and convert them to readable .cbz format.  
# Set working directory
$workingDir = "<insert folder path that has the non readable digitial comics>"
Set-Location $workingDir

# Create timestamped log file
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $workingDir "conversion_log_$timestamp.txt"
Add-Content $logFile "`n=== Script started at $(Get-Date) ===`n"

# Step 1: Rename all .cbr files to .rar
Get-ChildItem -Filter *.cbr | ForEach-Object {
    $newName = $_.BaseName + ".rar"
    Rename-Item $_.FullName -NewName $newName
    Add-Content $logFile "Renamed '$($_.Name)' to '$newName'"
}

# Step 2: Extract each .rar file
Get-ChildItem -Filter *.rar | ForEach-Object {
    $baseName = $_.BaseName
    $extractPath = Join-Path $workingDir $baseName
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

    & "C:\Program Files\7-Zip\7z.exe" x $_.FullName "-o$extractPath" -y
    Add-Content $logFile "Extracted '$($_.Name)' to '$extractPath'"
}

# Step 3: Compress each extracted folder to .zip and rename to .cbz
Get-ChildItem -Directory | ForEach-Object {
    $zipName = "$($_.Name).zip"
    $zipPath = Join-Path $workingDir $zipName

    Compress-Archive -Path (Join-Path $_.FullName '*') -DestinationPath $zipPath
    Add-Content $logFile "Compressed '$($_.Name)' to '$zipName'"

    # Rename .zip to .cbz
    $cbzName = "$($_.Name).cbz"
    $cbzPath = Join-Path $workingDir $cbzName
    Rename-Item $zipPath $cbzPath
    Add-Content $logFile "Renamed '$zipName' to '$cbzName'"

    # Delete original .rar file
    $rarFile = "$($_.Name).rar"
    $rarPath = Join-Path $workingDir $rarFile
    if (Test-Path $rarPath) {
        Remove-Item $rarPath -Force
        Add-Content $logFile "Deleted original file '$rarFile'"
    }

    # Delete extracted folder
    Remove-Item $_.FullName -Recurse -Force
    Add-Content $logFile "Deleted folder '$($_.Name)'"
}

Add-Content $logFile "`n=== Script completed at $(Get-Date) ===`n"
