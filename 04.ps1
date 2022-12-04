#VM: W11Client
#Image: Windows 11 Pro

#Get Initial variables from Json
$Variables = Get-Content "_variables.json" | ConvertFrom-Json

$RG= $Variables.Variable.RG
$Vnet= $Variables.Variable.Vnet
$Subnet= $Variables.Variable.Subnet
$Admin= $Variables.Variable.Admin
$Password= $Variables.Variable.Password

#VM Details
$VM_Name="W11Client"
$Public_Ip="pm-projekt-w10-client"
$Nsg="pm-projekt-nsg"
$Ip="172.16.0.20"

#Set default ResourceGroup
az configure --defaults group=$RG

#VM Create
Write-Host "VM Create: $VM_Name" -ForegroundColor Red
az vm create --name $VM_Name `
--priority Spot `
--max-price -1 `
--eviction-policy Deallocate `
--resource-group $RG `
--image microsoftwindowsdesktop:windows-11:win11-21h2-pro:latest `
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
Write-Host "Change IP to Static($Ip) on $NIC" -ForegroundColor Red
$IPConfig= "ipconfig" + $VM_Name
az network nic ip-config update `
--name $IPConfig `
--resource-group $RG `
--nic-name $NIC `
--private-ip-address $Ip

#Download script from Github
Write-Host "Download scripts from Github (04_scripts.ps1)" -ForegroundColor Red

az vm run-command invoke `
   -g $RG `
   -n $VM_Name `
   --command-id RunPowerShellScript `
   --scripts "wget https://raw.githubusercontent.com/atiradeon86/PM-Projekt/main/04_scripts.ps1 -OutFile c:\04_scripts.ps1"

#Run script
Write-Host "Run script: 04_scripts.ps1" -ForegroundColor Red
az vm run-command invoke `
-g $RG `
-n $VM_Name `
--command-id RunPowerShellScript `
--scripts "c:\04_scripts.ps1"