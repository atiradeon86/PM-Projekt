#Get Initial variables from Json
$Variables = Get-Content "_variables.json" | ConvertFrom-Json

$RG= $Variables.Variable.RG
$Vnet= $Variables.Variable.Vnet
$Subnet= $Variables.Variable.Subnet
$DC_Server_Ip= $Variables.Variable.DC_Server_Ip
$Admin= $Variables.Variable.Admin
$Password= $Variables.Variable.Password

#VM Details
$VM_Name="DC1";
$Public_Ip="pm-projekt-dc1"
$Nsg="pm-projekt-nsg";

#Set default ResourceGroup
az configure --defaults group=$RG

#Create Networking
az network vnet create --name $Vnet `
--address-prefix 172.16.0.0/16 `
--subnet-name $Subnet `
--subnet-prefix 172.16.0.0/24

#VM Create
echo "VM Create: $VM_Name"
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
echo "Change IP to Static($DC_Server_Ip) on $NIC"
$IPConfig= "ipconfig" + $VM_Name
az network nic ip-config update `
--name $IPConfig `
--resource-group $RG `
--nic-name $NIC `
--private-ip-address $DC_Server_Ip

#Download scripts from Github
echo "Download scripts from Github (01_dc_install.ps1, 01_dc_ou_users.ps1, 01_dns.ps1)"
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

echo "DC install"
echo "Cannot run from powershell ... :( - Force not working with Install-ADDSForest)"
   
#The target server will be configured as a domain controller. The server needs to be restarted manually when this
#operation is complete.
#Do you want to continue with this operation?
   
az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts "c:\01_dc_install.ps1"
   
echo "DC is currently in installing state ..."

$confirmation = Read-Host "Please confirm that your server booted up after restarting ... [y]"
if ($confirmation -eq 'y') {
      
#Run OU + Users scripts + Shared Folder BugFix GPO
echo "Run OU + Users scripts + Shared Folder BugFix GPO"

az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts "c:\01_dc_ou_users.ps1"

 #Run DNS Scripts
echo "Run DNS Scripts"

az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts "c:\01_dns.ps1"  

#DHCP Role Install
echo "DHCP Role Install"

az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts "c:\01_dhcp_role.ps1"  

}