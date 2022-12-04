#Get Initial variables from Json
$Variables = Get-Content "_variables.json" | ConvertFrom-Json

$RG= $Variables.Variable.RG
$Vnet= $Variables.Variable.Vnet
$Subnet= $Variables.Variable.Subnet
$DC_Server_Ip= $Variables.Variable.DC_Server_Ip
$Admin= $Variables.Variable.Admin
$Password= $Variables.Variable.Password

#VM Details
$VM_Name="DC1"
$Public_Ip="PM-Projektdc1"
$Nsg="PM-Projektnsg"

#Set default ResourceGroup
az configure --defaults group=$RG

#Create Networking
az network vnet create --name $Vnet `
--address-prefix 172.16.0.0/16 `
--subnet-name $Subnet `
--subnet-prefix 172.16.0.0/24

#VM Create
Write-Host "VM Create: $VM_Name" -ForegroundColor Red
az vm create --name $VM_Name `
--priority Spot `
--max-price -1 `
--eviction-policy Deallocate `
--resource-group $RG `
--image MicrosoftWindowsServer:WindowsServer:2019-datacenter-gensecond:latest `
--size Standard_D2as_v4 `
--authentication-type password `
--admin-username $Admin `
--admin-password $Password `
--nsg-rule RDP `
--storage-sku StandardSSD_LRS `
--vnet-name $Vnet `
--subnet $Subnet `
--public-ip-address $Public_Ip `
--nsg $Nsg `
--public-ip-sku Basic `
--public-ip-address-allocation dynamic `
--nic-delete-option Delete `
--os-disk-delete-option Delete

#Change IP to Static on NIC
$NIC= $VM_Name + "VMNic";
Write-Host "Change IP to Static($DC_Server_Ip) on $NIC"
$IPConfig= "ipconfig" + $VM_Name
az network nic ip-config update `
--name $IPConfig `
--resource-group $RG `
--nic-name $NIC `
--private-ip-address $DC_Server_Ip

#Enable Icmp on NSG for Test-Netconnection 
Write-Host "Enable Icmp on NSG fot Test-Netconnection" -ForegroundColor Red
az network nsg rule create `
 --nsg-name "$Nsg" `
 --name "Enable ICMP" `
 --description "Enable Icmp on NSG fot Test-Netconnection" `
 --protocol "Icmp" `
 --direction "Inbound" `
 --priority "1010" `
 --destination-port-ranges "*"

#Download scripts from Github

Write-Host "Download scripts from Github (01_dc_install.ps1, 01_dc_ou_users.ps1, 01_dns.ps1, 01_dhcp_role.ps1 )" -ForegroundColor Red
az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts "wget https://raw.githubusercontent.com/atiradeon86/PM-Projekt/main/01_dc_install.ps1 -OutFile c:\01_dc_install.ps1"

az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts "wget https://raw.githubusercontent.com/atiradeon86/PM-Projekt/main/01_dc_ou_users.ps1 -OutFile c:\01_dc_ou_users.ps1"

az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts "wget https://raw.githubusercontent.com/atiradeon86/PM-Projekt/main/01_dns.ps1 -OutFile c:\01_dns.ps1"

   az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts "wget https://raw.githubusercontent.com/atiradeon86/PM-Projekt/main/01_dhcp_role.ps1 -OutFile c:\01_dhcp_role.ps1"  

Write-Host "ADDS DC Install" -ForegroundColor Red
   
az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts "c:\01_dc_install.ps1"
    

#Check VM is rebooted?
$port = "3389"

do {
   Write-Host "Waiting for reboot" -ForegroundColor Red
   sleep 3
   $public_ip= az vm show -d -g $RG -n $VM_Name --query publicIps -o tsv    
   Write-Host $public_ip
} until(Test-NetConnection $public_ip -Port 3389 | ? { $_.TcpTestSucceeded} )

#Wait 10 minute after reboot because of AD-Forest Install (Group Policy changes on reboot)

 $Seconds = 600
 $EndTime = [datetime]::UtcNow.AddSeconds($Seconds)
 
 while (($TimeRemaining = ($EndTime - [datetime]::UtcNow)) -gt 0) {
   Write-Progress -Activity 'Watiting for...' -Status ADDS... -SecondsRemaining $TimeRemaining.TotalSeconds
   Start-Sleep 1
 }

#DHCP Role Install
Write-Host "DHCP Role Install" -ForegroundColor Red

az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts "c:\01_dhcp_role.ps1" 

#Run DNS Scripts
Write-Host "Run DNS Scripts" -ForegroundColor Red

az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts "c:\01_dns.ps1"  

#Run OU + Users scripts + Shared Folder BugFix GPO
Write-Host "Run OU + Users scripts + Shared Folder BugFix GPO" -ForegroundColor Red

az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts "c:\01_dc_ou_users.ps1"

Write-Host "The First part is finished ... :)" -ForegroundColor Green