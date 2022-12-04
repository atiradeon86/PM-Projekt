New- item - itemtype - directory -path "C:\Logs"
Start-Transcript -Path "C:\Logs\04_scripts.txt"

#Setup DNS for AD domain join

$Ip="172.16.0.20"
$DC="172.16.0.10"
$Ext_Dns="8.8.8.8"

$interface=  Get-NetIPAddress | Where-Object IPAddress -eq $Ip
$If_index= $interface.InterfaceIndex
Set-DnsClientServerAddress -InterfaceIndex $If_index -ServerAddresses ($DC,$Ext_Dns)

#Download and run AD Join scripts
wget https://raw.githubusercontent.com/atiradeon86/PM-Projekt/main/_ad_join.ps1 -OutFile c:\_ad_join.ps1

Invoke-Item (start powershell (c:\_ad_join.ps1))

#Cleanup
del c:\*.ps1
del c:\_variables.json

Stop-Transcript