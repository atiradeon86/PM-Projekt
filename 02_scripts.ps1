Start-Transcript -Path "C:\Logs\02_scripts.txt"

#Get Initial variables from Json
wget https://raw.githubusercontent.com/atiradeon86/PM-Projekt/main/_variables.json -OutFile c:\_variables.json
$Variables = Get-Content "c:\_variables.json" | ConvertFrom-Json

$Admin= $Variables.Variable.Admin
$Password= $Variables.Variable.Password
$Domain=$Variables.Variable.Domain

#Install FS-Resource-Manager
Install-WindowsFeature -Name FS-Resource-Manager –IncludeManagementTools

#Install Data-Deduplication
Install-WindowsFeature -Name FS-Data-Deduplication

#Creating Folders
$Driver_letter="S"


$folders=@("Hallgatok","Oktatok ","Vizsga","Users")
foreach ($folder in $folders) {
    New-item -itemtype Directory -path "S:\Shares\$folder"
}

#Creating SMB Shares
New-SmbShare -Name "hallgatok" -Path "S:\Shares\Hallgatok"
New-SmbShare -Name "oktatok" -Path "S:\Shares\Oktatok"
New-SmbShare -Name "vizsga" -Path "S:\Shares\Vizsga"

#Debug -> Deleting SMB Shares-<
#Remove-SmbShare -Name "hallgatok" -force
#Remove-SmbShare -Name "oktatok" -force
#Remove-SmbShare -Name "vizsga" -force

#SMB Grants

#hallgatok

Grant-SmbShareAccess -Name hallgatok -AccountName Administrators -AccessRight Full -force
Grant-SmbShareAccess -Name hallgatok -AccountName hallgatok -AccessRight Change -force

#Debug
Get-SmbShareAccess -Name hallgatok

#oktatok
Grant-SmbShareAccess -Name oktatok -AccountName Administrators -AccessRight Full -force
Grant-SmbShareAccess -Name oktatok -AccountName oktatok -AccessRight Change -force

#Debug
Get-SmbShareAccess -Name oktatok

#vizsga
Grant-SmbShareAccess -Name vizsga -AccountName Administrators -AccessRight Full -force
Grant-SmbShareAccess -Name vizsga -AccountName hallgatok -AccessRight Change -force
Grant-SmbShareAccess -Name vizsga -AccountName oktatok -AccessRight Read -force

#Debug
Get-SmbShareAccess -Name vizsga

##Install AD Services + ManagementTools for Powershell modules
Install-WindowsFeature –Name AD-Domain-Services –IncludeManagementTools

#Create home folders + Enable Quota
$names = c -Filter * | Select-Object -ExpandProperty SamAccountName

#Creating Quota Template 
New-FsrmQuotaTemplate -Name "Home-Folders" -Description "Limit usage to 500 MB" -Size 500MB -Threshold (New-FsrmQuotaThreshold -Percentage 90)

foreach ($name in $names) {
    New-item -itemtype Directory -path S:\Shares\Users\$name
    $path = "S:\Shares\Users\" +$name
    New-FsrmQuota -Path $path -Description "Limit usage to 500 MB" -Template "Home-Folders"
}

#Add NTFS ACL Rights
foreach ($name in $names) {
    $acl = Get-Acl -Path "S:\Shares\Users\$name"
    $ace = New-Object System.Security.Accesscontrol.FileSystemAccessRule ("$name", "Full", "Allow")
    $acl.AddAccessRule($ace)
    Set-Acl -Path "S:\Shares\Users\$name" -AclObject $acl
}

#Debug Quota
Get-FsrmQuota

#Map home folders /* Change Map From GPO */

<#
#Create Credential Object
$userName = "$Admin@$Domain"
$userPassword = "$Password"

$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

Invoke-Command -ComputerName DC1 -Credential $credObject -ScriptBlock {  

$OU_List=@("Hallgatok","Oktatok")

foreach ($ou in $OU_List) {
    Get-ADUser -SearchBase "OU=$ou,DC=project,DC=local" -Filter *  | % { Set-ADUser $_ -HomeDrive "Z:" -HomeDirectory ('\\FS1\Home\' + $_.SamAccountName) }  
}

}
#>

#Cleanup
del c:\*.ps1
del c:\01_variables.json

Stop-Transcript