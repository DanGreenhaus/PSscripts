#this script is designed to retrieve NSG info for databricks assets.
if (!(Get-Module -ListAvailable -Name Az*)) {#if all Azure Modules if they don't currently exist
    Write-Host "Module does not exist; installing Azure Management Module from PSGallery"
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
}
if (!(Get-AzContext)){#connects to Azure if you are not currently connected
   Write-Host "You are not connected to Azure; Please sign in to your account"
   Connect-AzAccount
}

$sub = Get-AzSubscription | Select-Object Name, Id
$table = @()
$sub | ForEach-Object {
    Set-AzContext -Subscription $_.Name
    $currentSub = $_.Name
    $subID = $_.Id 
    $databricks = Get-AzDatabricksWorkspace 
    if($databricks -ne $null){
        Write-Host -ForegroundColor Green ("> Databricks Workspace found in subscription: " +$currentSub) 
        foreach($workspace in $databricks){
            $NewRow = [ordered]@{"Subscription Name"=$currentSub;"Subscription ID"=$subID; "Databrick Name" =$workspace.Name; "Current RG" = $workspace.ManagedResourceGroupId; "MS Managed Vnet (Y/N)" = ""; "CX Vnet ID" = $workspace.CustomVirtualNetworkIdValue; "CX Public Subnet Name" = $workspace.CustomPublicSubnetNameValue; "CX Private Subnet Name" = $workspace.CustomPrivateSubnetNameValue; "CX Public Subnet IP" =""; "CX Private Subnet IP"=""; "CX Public Subnet NSG" = ""; "CX Private Subnet NSG" = ""; "CX Public Subnet NSG ID" = ""; "CX Private Subnet NSG ID" = ""} #check to see if the Vnet is customer defined
            if($workspace.CustomVirtualNetworkIdValue -ne $null){
                $NewRow.'MS Managed Vnet (Y/N)' = "N" #determine attached NSG to pub/prv subnets
                $NSGpub = Get-AzNetworkSecurityGroup | Where-Object {$_.Subnets.Id -contains ($workspace.CustomVirtualNetworkIdValue+"/subnets/"+$workspace.CustomPublicSubnetNameValue)} | Select-Object Name, Id
                $NSGprv = Get-AzNetworkSecurityGroup | Where-Object {$_.Subnets.Id -contains ($workspace.CustomVirtualNetworkIdValue+"/subnets/"+$workspace.CustomPrivateSubnetNameValue)} | Select-Object Name, Id 
                $NewRow.'CX Public Subnet NSG' = $NSGpub.Name
                $NewRow.'CX Public Subnet NSG ID' = $NSGpub.Id
                $NewRow.'CX Private Subnet NSG' = $NSGprv.Name
                $NewRow.'CX Private Subnet NSG ID' = $NSGprv.Id #determine address range of subnets
                $vnetname = $workspace.CustomVirtualNetworkIdValue.Split('/')[8]
                $vnetobj = Get-AzVirtualNetwork -Name $vnetname 
                $subnets = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnetobj
                $pubIP = ($subnets | Where-Object {$_.name -eq $workspace.CustomPublicSubnetNameValue} | Select-Object @{name='AddressPrefix';expression={$_.AddressPrefix -join " "}}).AddressPrefix
                $prvIP = ($subnets | Where-Object {$_.name -eq $workspace.CustomPrivateSubnetNameValue} | Select-Object @{name='AddressPrefix';expression={$_.AddressPrefix -join " "}}).AddressPrefix
                $NewRow.'CX Public Subnet IP' = $pubIP
                $NewRow.'CX Private Subnet IP' = $prvIP
            }
            else{
            $NewRow.'MS Managed Vnet (Y/N)' = "Y"
            } $table += $NewRow
        }
    }
    else{
    Write-Host -ForegroundColor Red ("> NO Databricks Workspaces found in subscription: " +$currentSub)
    }
}    
#write csv
$(Foreach($z in $table){
    New-object psobject -Property $z
}) | Export-Csv -NoTypeInformation ("$env:USERPROFILE\Desktop\Azure PS\" + (get-date -UFormat %m%d%y) + "_databricksaudit.csv")
        
        
        
#write txt
Foreach($z in $table){
    $z | Out-File -Append ("$env:USERPROFILE\Desktop\Azure PS\" + (get-date -UFormat %m%d%y) + "_databricksaudit.txt")
    "" | Out-File -Append ("$env:USERPROFILE\Desktop\Azure PS\" + (get-date -UFormat %m%d%y) + "_databricksaudit.txt")
} 
          
