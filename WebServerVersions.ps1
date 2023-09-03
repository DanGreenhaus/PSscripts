$Websites=@("<insert website URL>"

)

$Website="<insert website URL>"
foreach ($website in $Websites){
    Write-Host
    Write-Host $website
    ((Invoke-WebRequest -Method Head -SkipHttpErrorCheck -SkipCertificateCheck -uri $website).headers).server
}
$Website="<insert website URL>"
((Invoke-WebRequest -Method Head -SkipHttpErrorCheck -SkipCertificateCheck -uri $website).headers).server #to check the apache version
$Website="<insert website URL>"
((Invoke-WebRequest -Method Head -SkipHttpErrorCheck -SkipCertificateCheck -uri $website).headers)."X-powered-by" #to check the PHP version


(Invoke-WebRequest -Method Head -uri $Website -SkipHttpErrorCheck -SkipCertificateCheck).rawcontent

nmap -p 22 -A -sV -Pn --reason <insert URL here> #run this command from the venom server to find the SSH version