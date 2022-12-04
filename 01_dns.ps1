Start-Transcript -Path "C:\Logs\01_dns_role.txt" 
#Add New Zone
Add-DnsServerPrimaryZone -Name "bryan-pmproject.hu" -ReplicationScope "Forest" -PassThru

#Add A Records
Add-DnsServerResourceRecordA -Name "bryan-pmproject.hu" -ZoneName "bryan-pmproject.hu" -AllowUpdateAny -IPv4Address "172.16.0.10" -TimeToLive 01:00:00
Add-DnsServerResourceRecordA -Name "dc" -ZoneName "bryan-pmproject.hu" -AllowUpdateAny -IPv4Address "172.16.0.10" -TimeToLive 01:00:00
Add-DnsServerResourceRecordA -Name "fs1" -ZoneName "bryan-pmproject.hu" -AllowUpdateAny -IPv4Address "172.16.0.11" -TimeToLive 01:00:00

#Add Cname REcords
Add-DnsServerResourceRecordCName -Name "www" -HostNameAlias "fs1.bryan-pmproject.hu" -ZoneName "bryan-pmproject.hu"
Add-DnsServerResourceRecordCName -Name "mail" -HostNameAlias "dc.bryan-pmproject.hu" -ZoneName "bryan-pmproject.hu"

$userName = 'Trainer'
$userPassword = 'Demo1234#'
$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force

$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)
Stop-Transcript