#Install FS-Resource-Manager
Install-WindowsFeature -Name FS-Resource-Manager –IncludeManagementTools

#Install Data-Deduplication
Install-WindowsFeature -Name FS-Data-Deduplication

#Creating Folders
$Driver_letter="S"

echo "Creating Folders"
$folders=@("Hallgatok","Oktatok ","Vizsga","Users")
foreach ($folder in $folders) {
    New-item -itemtype Directory -path "S:\Shares\$folder"
}
echo "Creating SMB Shares"
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
echo "Set SMB Acces rights"
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

#Create Users Folder Base Share
New-SmbShare -Name "Home" -Path "S:\Shares\Users"
Grant-SmbShareAccess -Name Home -AccountName Administrators -AccessRight Full -force

##Install AD Services + ManagementTools for Powershell modules
Install-WindowsFeature –Name AD-Domain-Services –IncludeManagementTools

#Create home folders + Enable Quota
$names = Get-ADUser -Filter * | Select-Object -ExpandProperty Name

#Creating Quota Template 
echo "Create Quota Template + Apply"
New-FsrmQuotaTemplate -Name "Home-Folders" -Description "Limit usage to 500 MB" -Size 500MB -Threshold (New-FsrmQuotaThreshold -Percentage 90)

foreach ($name in $names) {
    New-item -itemtype Directory -path \\FS1\Home\$name
    $path = "S:\Shares\Users\" +$name
    New-FsrmQuota -Path $path -Description "Limit usage to 500 MB" -Template "Home-Folders"
}

#Debug Quota
Get-FsrmQuota

#Map home folders

#Create Credential Object
$userName = 'demo@project.local'
$userPassword = 'Demo1234####'
$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

Invoke-Command -ComputerName DC1 -Credential $credObject -ScriptBlock {  

echo "Map User Home Folders"
$OU_List=@("Hallgatok","Oktatok")

foreach ($ou in $OU_List) {
    Get-ADUser -SearchBase "OU=$ou,DC=project,DC=local" -Filter *  | % { Set-ADUser $_ -HomeDrive "Z:" -HomeDirectory ('\\FS1\Home\' + $_.SamAccountName) }  
}

}