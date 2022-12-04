Start-Transcript -Path "C:\Logs\01_dc_install.txt" 

wget https://raw.githubusercontent.com/atiradeon86/PM-Projekt-Testing/main/_variables.json -OutFile c:\01_variables.json

#Get Initial variables from Json
$Variables = Get-Content "c:\01_variables.json" | ConvertFrom-Json
$Password= $Variables.Variable.Password
$Admin= $Variables.Variable.Admin

#Data Setup
$DC_Server_Ip="172.16.0.10"
$External_DNS="8.8.8.8"

#DNS Setup   
$interface=  Get-NetIPAddress | Where-Object IPAddress -eq $DC_Server_Ip
$If_index= $interface.InterfaceIndex
   
Set-DnsClientServerAddress -InterfaceIndex $If_index -ServerAddresses ("$DC_Server_Ip","$External_DNS")

#Install Windows Server Backup Feature
Install-WindowsFeature Windows-Server-Backup

<#
#Creating Tasks for next startup

# You can write script runs on startup but not running on this shit ... If you start manual running without any problems

$taskPrincipal = New-ScheduledTaskPrincipal -UserId "$Admin" -RunLevel Highest

#01_dc_ou_users.ps1
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass C:\01_dc_ou_users.ps1"
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet
$task = New-ScheduledTask -Action $action  -Trigger $trigger -Settings $settings -Principal $taskPrincipal
Register-ScheduledTask DC-Users -InputObject $task 
Set-ScheduledTask -TaskName 'DC-Users' -User $taskPrincipal.UserID -Password "$Password"

#01_dns.ps1
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass C:\01_dns.ps1"
$trigger = New-ScheduledTaskTrigger -AtStartup 
$settings = New-ScheduledTaskSettingsSet
$task = New-ScheduledTask -Action $action  -Trigger $trigger -Settings $settings -Principal $taskPrincipal
Register-ScheduledTask DNS-Scripts -InputObject $task 
Set-ScheduledTask -TaskName 'DNS-Scripts' -User $taskPrincipal.UserID -Password "$Password"

#01_dhcp_role.ps1
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass C:\01_dhcp_role.ps1"
$trigger = New-ScheduledTaskTrigger -AtStartup 
$settings = New-ScheduledTaskSettingsSet
$task = New-ScheduledTask -Action $action  -Trigger $trigger -Settings $settings -Principal $taskPrincipal
Register-ScheduledTask DHCP-Scripts -InputObject $task 
Set-ScheduledTask -TaskName 'DHCP-Scripts' -User $taskPrincipal.UserID -Password "$Password"
#>

#Install AD Services + ManagementTools
Install-WindowsFeature –Name AD-Domain-Services –IncludeManagementTools

#SafeMode Admin Password Create
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
  
Stop-Transcript
Restart-Computer -Force