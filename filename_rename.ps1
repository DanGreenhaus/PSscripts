#to remove a phrase that has been appended to the end of a bunch of file names
$dir = "<insert folder path of files here>" #this is the folder location that needs to be replaced
$phrase = " <Replace this stuff>" #this with phrase you are looking to remove
#remove the last number of characters in the file names
$length=$phrase.Length 
Get-ChildItem $dir -Recurse| Where-Object { $_.Name -like "*$phrase*" } | `
  Rename-Item -NewName { $_.name.substring(0,$_.BaseName.length-$length)+$_.Extension}# -WhatIf -verbose

#if you have multiple items:
$phrases=@(
    "<phrase 1>"
    "<Phrase 2>" 
    "<etc>" 
)
foreach ($phrase in $phrases){
  Get-ChildItem $dir -Recurse| Where-Object { $_.Name -like "*$phrase*" } | Rename-Item -NewName `
    { $_.Name -replace [regex]::Escape($Phrase),""}# -WhatIf 
}

#if you need to eliminate the _ in a filename, and replace it with a space
Get-ChildItem $dir -Recurse| Where-Object { $_.Name -like "*$phrase*" } | Rename-Item -NewName `
  { $_.Name -replace "_"," " }

#to rename certain files that meet case criteria
Get-ChildItem $dir -Recurse| Where-Object { $_.Name -clike "*$phrase*" } | Rename-Item -NewName `
  { $_.Name -replace "Deadly Class v","Deadly Cass Vol. " }

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
