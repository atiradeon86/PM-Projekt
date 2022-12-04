New-item -itemtype directory -path "C:\Logs"
Start-Transcript -Path "C:\Logs\02_dns_setup.txt" 
#Setup DNS for AD domain join

$Ip="172.16.0.11"
$DC="172.16.0.10"
$Ext_Dns="8.8.8.8"

$interface=  Get-NetIPAddress | Where-Object IPAddress -eq $Ip
$If_index= $interface.InterfaceIndex
Set-DnsClientServerAddress -InterfaceIndex $If_index -ServerAddresses ($DC,$Ext_Dns)

Stop-Transcript