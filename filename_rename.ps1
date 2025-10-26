#to remove a phrase that has been appended to the end of a bunch of file names
$dir = "<insert folder path of files here>" #this is the folder location that needs to be replaced
$phrase = " <Replace this stuff>" #this with phrase you are looking to remove
#remove the last number of characters in the file names
$length=$phrase.Length 
Get-ChildItem $dir -Recurse| Where-Object { $_.Name -like "*$phrase*" } |
  Rename-Item -NewName { $_.name.substring(0,$_.BaseName.length-$length)+$_.Extension}# -WhatIf -verbose

#if you have multiple items:
$phrases=@(
    "<phrase 1>"
    "<Phrase 2>" 
    "<etc>" 
)
foreach ($phrase in $phrases){
# Initialize a report variable
$report = @()
foreach ($phrase in $phrases) {
 # Recursively get all files and folders under $dir
    Get-ChildItem $dir -Recurse | Where-Object {
        # Match items whose names contain the current phrase
        $_.Name -match [regex]::Escape($phrase)
    } | ForEach-Object {
        # Store the original name
        $original = $_.Name

        # Remove the phrase from the name
        $proposed = $original -replace [regex]::Escape($phrase), ""

        # Only proceed if the name actually changes
        if ($proposed -ne $original) {

            # Determine the new path based on whether it's a folder or file
            if ($_.PSIsContainer) {
                # For folders: use Split-Path to get parent directory
                $parentPath = Split-Path $_.FullName
                $newPath = Join-Path $parentPath $proposed
            } else {
                # For files: use .DirectoryName to get parent directory
                $parentPath = $_.DirectoryName
                $newPath = Join-Path $parentPath $proposed
            }

            # Rename the item (preview only with -WhatIf; remove -WhatIf to apply)
            Rename-Item -Path $_.FullName -NewName $newPath -Verbose #-WhatIf

            # Log the rename operation to the report
            $report += [PSCustomObject]@{
                Phrase         = $phrase
                Type           = if ($_.PSIsContainer) { "Folder" } else { "File" }
                Path           = $_.FullName
                OriginalName   = $original
                UpdatedName    = $proposed
            }
        }
    }
}

# create the report and folder path
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss" # Generate timestamp string
$reportFolder = Join-Path $dir "Reports"# Define the Reports folder path
if (-not (Test-Path $reportFolder)) { New-Item -Path $reportFolder -ItemType Directory | Out-Null }# Create the Reports folder if it doesn't exist
$csvPath = Join-Path $reportFolder "rename_files_and_folders_$timestamp.csv"# Build full CSV path with timestamp
# Export the report
$report | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 -Force

}

#if you need to eliminate the _ in a filename, and replace it with a space
Get-ChildItem $dir -Recurse| Where-Object { $_.Name -like "*$phrase*" } | 
Rename-Item -NewName { $_.Name -replace "_"," " }

#to rename certain files that meet case criteria
Get-ChildItem $dir -Recurse| Where-Object { $_.Name -clike "*$phrase*" } |
 Rename-Item -NewName { $_.Name -replace "Deadly Class v","Deadly Cass Vol. " }

#these commands will find folders with a particular phrase in the name
Get-ChildItem $dir -recurse -filter $phrase -Directory | ForEach-Object { $_.fullname }
Get-ChildItem $dir -recurse | Where-Object {$_.PSIsContainer -eq $true -and $_.Name -match "$phrase"}
Get-ChildItem $dir -recurse -filter "<search criteria>" | Remove-Item

#to list all folders in a directory that match a particular phrase
Get-ChildItem $dir *$phrase* -Recurse -Directory

#if you have folders in the zip files, use this command to extract them into one main folder
Get-ChildItem $dir\zipfiles\*.* -recurse | Move-Item -Destination "$dir\zipfiles\files"

#or
Get-ChildItem "$dir\*.zip" -Recurse |Expand-Archive -DestinationPath "$dir\" -Force #unzips files into root folder
Get-ChildItem "$dir\*.zip" -Recurse | Remove-Item #removes the zip files after they are extracted

#to remove trailing spaces
Get-ChildItem -Path $targetDirectory -File | ForEach-Object {
  $originalName = $_.Name.TrimEnd()  # Trim trailing spaces first
  $pattern = "\((.*?)\)"
  If ($originalName -match $pattern) {
      $newName = $matches[1] + " - " + $originalName.Replace($matches[0], "").TrimEnd()
      $newName = $_.Name.TrimEnd() 
      Rename-Item -Path $_.FullName -NewName $newName -ErrorAction Stop
      Write-Host "Renamed $_ to $newName"  # Provide feedback on successful renaming
  }
}

