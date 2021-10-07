#to remove a phrase that has been appended to the end of a bunch of file names
$dir = "C:\Users\Dan\Downloads" #this is the folder location that needs to be replaced
$phrase = " Repalce this stuff" #<replace this with phrase you are looking to remove>
#remove the last number of characters in thefile names
$length=$phrase.Length 
Get-ChildItem $dir -Recurse| Where-Object { $_.Name -like "*$phrase*" } | Rename-Item -NewName { $_.name.substring(0,$_.BaseName.length-$length)+$_.Extension}# -WhatIf -verbose
