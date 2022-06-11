$pub=(Read-Host "Which publisher do you want to clean up? (M)arvel or (D)C").ToUpper()
#use this section for marvel books
If ($pub -eq 'M'){$publisher="Marvel"}

#use this section for DC books
If ($pub -eq 'D'){$publisher="DC"}

$dups=(Read-Host "Do you want to remove duplicates? Y or N").ToUpper()

#this section does most of the work
$Path="D:\Profile Data File Storage\Dan\Pictures\comics\unfiled $publisher"

$dest="$path\unread"
$dirs = gci -Path $dest -filter "$publisher week*"

gci $dirs.fullname -filter *.cbr | move-item -Destination $dest -Force
gci $dirs.fullname -filter *.txt | Remove-Item -Force
gci $dirs.fullname -filter *.dat | Remove-Item -force

if ($dups -eq 'Y'){
    #if you have duplicates..... https://stackoverflow.com/questions/19650516/compare-folders-and-delete-duplicates
    $one = Get-ChildItem "$path\unread\"
    $two = Get-ChildItem "$path"

    $matches = (Compare-Object -ReferenceObject $one  -DifferenceObject $two -Property Name,Length -ExcludeDifferent -IncludeEqual)

    foreach ($file in $matches)
    {
        Remove-Item "$path\unread\$($file.Name)" -Force
    }
}