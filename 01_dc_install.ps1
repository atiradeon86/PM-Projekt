#Data Setup
$DC_Server_Ip="172.16.0.10"
$External_DNS="8.8.8.8"

#DNS Setup   
$interface=  Get-NetIPAddress | Where-Object IPAddress -eq $DC_Server_Ip
$If_index= $interface.InterfaceIndex
   
Set-DnsClientServerAddress -InterfaceIndex $If_index -ServerAddresses ("$DC_Server_Ip","$External_DNS")

#Install Windows Server Backup Feature
Install-WindowsFeature Windows-Server-Backup

#Install AD Services + ManagementTools
Install-WindowsFeature –Name AD-Domain-Services –IncludeManagementTools

#SafeMode Admin Password Create
$Password="Demo1234#"
$Secure_Pwd = ConvertTo-SecureString $Password -AsPlainText -Force

Install-ADDSForest `
  -DomainName project.local `
  -CreateDnsDelegation:$false `
  -DatabasePath "C:\Windows\NTDS" `
  -DomainMode "7" `
  -DomainNetbiosName "project" `
  -ForestMode "7" `
  -InstallDns:$true `
  -LogPath "C:\Windows\NTDS" `
  -NoRebootOnCompletion:$True `
  -SysvolPath "C:\Windows\SYSVOL"`
  -SafeModeAdministratorPassword $Secure_Pwd `
  -Force 

Restart-Computer