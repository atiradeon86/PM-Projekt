#Add Organization Units
 $OU_List=@("PROJECT","Hallgatok","Oktatok","KliensGepek","Csoportok")

foreach ($ou in $OU_List) {
    New-ADOrganizationalUnit -Name "$ou" -Path "DC=project,DC=local"
}

#Default User Password
$Password = "Demo1234####" | ConvertTo-SecureString -AsPlainText -Force

#Add Users to Hallgatok OU
$Hallgatok_U=@("Gipsz Jakab","Beton Béla")
$Oktatok_U =@("Trainer")

foreach ($U in $Hallgatok_U) {  
    New-ADUser -Name "$U" -path "OU=hallgatok, DC=project, DC=local" -SamAccountName "$u" -UserPrincipalName "$u" -AccountPassword $Password -Enabled $true
}

#Add User/s to Oktatok OU
$Oktatok_U =@("Trainer")
foreach ($O in $Oktatok_U) {
    New-ADUser -Name "$O" -path "OU=oktatok, DC=project, DC=local" -SamAccountName "$O" -UserPrincipalName "$O" -AccountPassword $Password -Enabled $true
}

#Add Trainer to Domain Admins Group
Add-ADGroupMember -Identity "Domain Admins" -Members Trainer

#Add new ADGroups
New-ADGroup -Name "oktatok" -SamAccountName "oktatok" -GroupScope DomainLocal -DisplayName "Oktatók" -Path "OU=csoportok,DC=project,DC=local"
New-ADGroup -Name "hallgatok" -SamAccountName "hallgatok" -GroupScope DomainLocal -DisplayName "Hallgatók" -Path "OU=csoportok,DC=project,DC=local"

#Add users to ADGroups
Add-ADGroupMember -Identity hallgatok -Members "Gipsz Jakab","Beton Béla"
Add-ADGroupMember -Identity oktatok -Members "Trainer"

#BugFix for Shared Folder https://windowsreport.com/folder-doesnt-map/

#Creating the required GPO (Turn Off Fast Logon Optimization feature)
#Make Backup Backup-GPO -Name FLO-Path C:\ -Comment "Backup GPO FLO"
#Download
#Extract
#Import

#Install GPMC with ManagementTools 
Install-WindowsFeature GPMC -IncludeManagementTools 

#Create GPO
New-GPO -Name "FLO"

#Link GPO
New-GPLink -Name "FLO" -Target "dc=project,dc=local" 

#Download GPO
wget https://raw.githubusercontent.com/atiradeon86/PM-Projekt/main/Gpo.zip -OutFile c:\Gpo.zip

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Unzip "C:\gpo.zip" "C:\"

Import-GPO -BackupGpoName FLO -Path "C:\Gpo" -TargetName FLO