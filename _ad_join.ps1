wget https://raw.githubusercontent.com/atiradeon86/PM-Projekt-Testing/main/_variables.json -OutFile c:\01_variables.json

#Get Initial variables from Json
$Variables = Get-Content "c:\01_variables.json" | ConvertFrom-Json
$Password= $Variables.Variable.Password
$Admin= $Variables.Variable.Admin
$Domain= $Variables.Variable.Domain

$userPassword = "$Password"
$userName = "$Admin@$Domain"
$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName,$secStringPassword

Add-Computer -DomainName $domain -DomainCredential $Credential -Restart -Verbose