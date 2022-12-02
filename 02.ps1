#Gépnév: FS1
#Image: Windows Server Core 2019 Gen2

#Get Initial variables from Json
$Variables = Get-Content "_variables.json" | ConvertFrom-Json

$RG= $Variables.Variable.RG
$Vnet= $Variables.Variable.Vnet
$Subnet= $Variables.Variable.Subnet
$Admin= $Variables.Variable.Admin
$Password= $Variables.Variable.Password

#VM Details
$VM_Name="FS1";
$Public_Ip="pm-projekt-fs1"
$Nsg="pm-projekt-nsg";
$Ip="172.16.0.11"
$DiskName ="pm-project"

#Set default ResourceGroup
az configure --defaults group=$RG

#VM Create
echo "VM Create: $VM_Name"
az vm create --name $VM_Name `
--priority Spot `
--max-price -1 `
--eviction-policy Deallocate `
--resource-group $RG `
--image MicrosoftWindowsServer:WindowsServer:2019-datacenter-core-g2:latest `
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

#Creating new disk
echo "Creating new disk: $DiskName"
az disk create -g $RG -n $DiskName --size-gb 4 --sku StandardSSD_LRS

#Attaching disk to VM
echo "Attaching disk:$DiskName to $VM_Name"
az vm disk attach `
    --resource-group $RG `
    --vm-name $VM_Name `
    --name $DiskName 

#Download drive init script from Github
echo "Download scripts from Github (02_drive_init.ps1)"
az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts "wget https://raw.githubusercontent.com/atiradeon86/PM-Projekt/main/02_drive_init.ps1 -OutFile c:\02_drive_init.ps1"    

#Download DNS Setup script from Github -for AD
echo "Download scripts from Github (02_dns_setup.ps1)"
az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts "wget https://raw.githubusercontent.com/atiradeon86/PM-Projekt/main/02_dns_setup.ps1 -OutFile c:\02_dns_setup.ps1"    

#Change IP to Static on NIC
$NIC= $VM_Name + "VMNic";
echo "Change IP to Static($Ip) on $NIC"
$IPConfig= "ipconfig" + $VM_Name
az network nic ip-config update `
--name $IPConfig `
--resource-group $RG `
--nic-name $NIC `
--private-ip-address $Ip

#Run DNS Setup script
echo "Run script: 02_dns_setup.ps1"
az vm run-command invoke `
-g $RG `
-n $VM_Name `
--command-id RunPowerShellScript `
--scripts "c:\02_dns_setup.ps1"

#Run drive init script
echo "Run script: 02_drive_init.ps1"
az vm run-command invoke `
-g $RG `
-n $VM_Name `
--command-id RunPowerShellScript `
--scripts "c:\02_drive_init.ps1"

#Download scripts
echo "Download scripts from Github (02_scripts.ps1, _ad_join.ps1)"
az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts "wget https://raw.githubusercontent.com/atiradeon86/PM-Projekt/main/02_scripts.ps1 -OutFile c:\02_scripts.ps1"


az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts "wget https://raw.githubusercontent.com/atiradeon86/PM-Projekt/main/_ad_join.ps1 -OutFile c:\_ad_join.ps1"   

#Run AD Join script
echo "Run script: _ad_join.ps1"
az vm run-command invoke `
-g $RG `
-n $VM_Name `
--command-id RunPowerShellScript `
--scripts "c:\_ad_join.ps1"

#Wait 5 min (Time to restarting)
echo "Wait 5 min restarting" 
Start-Sleep -Seconds 300

#Run script (Files Sharing, Folders,Quota)
echo "Run script: c:\02_scripts.ps1"
az vm run-command invoke `
-g $RG `
-n $VM_Name `
--command-id RunPowerShellScript `
--scripts "c:\02_scripts.ps1"

echo "The Second part is finished ... :)"