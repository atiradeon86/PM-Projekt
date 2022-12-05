$Variables = Get-Content "c:\01_variables.json" | ConvertFrom-Json
$Password= $Variables.Variable.Password
$Admin= $Variables.Variable.Admin
$Default_ADUP = $Variables.Variable.Default_ADUP

Start-Transcript -Path "C:\Logs\01_dc_ou_users.txt" 

#Add Organization Units
 $OU_List=@("PROJECT","Hallgatok","Oktatok","KliensGepek","Csoportok")

foreach ($ou in $OU_List) {
    New-ADOrganizationalUnit -Name "$ou" -Path "DC=project,DC=local"
}

#Default User Password
$Password = "$Default_ADUP" | ConvertTo-SecureString -AsPlainText -Force

#Add Users to Hallgatok OU
$Hallgatok_U=@("Gipsz Jakab","Beton Béla")


$Oktatok_U =@("Trainer")

foreach ($U in $Hallgatok_U) {  
    $name = "project.local";
    $Sam = $U.replace(" ",'.').ToLower()
    $princ = "$U"+"`@$name"
    $split = $U.split(" ")

    New-ADUser -Name "$U" -path "OU=hallgatok, DC=project, DC=local" -SamAccountName "$Sam" -UserPrincipalName "$princ" -AccountPassword $Password -GivenName $split[0]   -Surname $split[1] -DisplayName "$U" -Enabled $true
}

#Add User/s to Oktatok OU
$Oktatok_U =@("Trainer","Ati")
foreach ($O in $Oktatok_U) {
    $name = "project.local";
    $Sam = $O.replace(" ",'.').ToLower()
    $princ = "$O"+"`@$name"
    $split = $O.split(" ")
    New-ADUser -Name "$O" -path "OU=oktatok, DC=project, DC=local" -SamAccountName "$Sam" -UserPrincipalName "$princ" -AccountPassword $Password -GivenName $split[0]   -Surname $split[1] -DisplayName "$O" -Enabled $true
}

#Add Trainer to Domain Admins Group
Add-ADGroupMember -Identity "Domain Admins" -Members Trainer
Add-ADGroupMember -Identity "Domain Admins" -Members Ati

#Add new ADGroups
New-ADGroup -Name "oktatok" -SamAccountName "oktatok" -GroupScope DomainLocal -DisplayName "Oktatók" -Path "OU=csoportok,DC=project,DC=local"
New-ADGroup -Name "hallgatok" -SamAccountName "hallgatok" -GroupScope DomainLocal -DisplayName "Hallgatók" -Path "OU=csoportok,DC=project,DC=local"

#Add users to ADGroups
Add-ADGroupMember -Identity hallgatok -Members "gipsz.jakab","beton.béla"
Add-ADGroupMember -Identity oktatok -Members "trainer"

#BugFix for Shared Folder https://windowsreport.com/folder-doesnt-map/

#Creating the required GPO (Turn Off Fast Logon Optimization feature)
#Make Backup Backup-GPO -Name FLO-Path C:\ -Comment "Backup GPO FLO"
#Backup-GPO -Name Shared-Folders -Path C:\ -Comment "Shared Folders"
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

Remove-Item -Recurse -Force C:\Gpo

#Import Shared-Folders GPO
# Backup-GPO -Name Shared-Folders -Path C:\ -Comment "Shared Folders"

#Create GPO
New-GPO -Name "Shared-Folders"

#Link GPO
New-GPLink -Name "Shared-Folders" -Target "dc=project,dc=local" 

#Download GPO
wget https://raw.githubusercontent.com/atiradeon86/PM-Projekt/main/Gpo2.zip -OutFile c:\Gpo2.zip

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Unzip "C:\Gpo2.zip" "C:\"

<#

!!!Item-level-targeting Works with OU, not with Security Groups!!!

#Fix Group SID values for GPO Rule Shared-Folders (For Drive Map Item-level-targeting)

Set-Location C:\Gpo\"{21AA0B2B-97A1-4489-9DE3-E7A1C5FFB6DC}"\DomainSysvol\GPO\User\Preferences\Drives\
$content = Get-Content -Path ".\drives.xml"

#Get actual SID oktatok
$oktatok="S-1-5-21-145901427-4149395719-1594107157-1108"

$oktatok_group =Get-ADGroup -Identity oktatok | Select -ExpandProperty SID
$oktatok_new=$oktatok_group.Value

#Get actual SID hallgatok
$hallgatok="S-1-5-21-145901427-4149395719-1594107157-1109"

$hallgatok_group =Get-ADGroup -Identity hallgatok | Select -ExpandProperty SID
$hallgatok_new=$hallgatok_group.Value

#Get actual SID - Domain Admins
$da="S-1-5-21-145901427-4149395719-1594107157-512"

$da_group =Get-ADGroup -filter * -properties * | select sid,name | Where -property name -eq "Domain Admins"
$da_new=$da_group.SID.Value

$newContent = $content -replace $oktatok, $oktatok_new  | Out-File -FilePath ".\drives.xml" -Encoding Utf8
$newContent = $content -replace $hallgatok, $hallgatok_new  | Out-File -FilePath  ".\drives.xml" -Encoding Utf8
$newContent = $content -replace $da, $da_new  | Out-File -FilePath ".\drives.xml" -Encoding Utf8

Set-Location C:\
#>

Import-GPO -BackupGpoName Shared-Folders -Path "C:\Gpo" -TargetName Shared-Folders

#Cleanup
Remove-Item -Recurse -Force C:\Gpo
del C:\Gpo.zip
del C:\Gpo2.zip
del c:\*.ps1
del c:\*.json