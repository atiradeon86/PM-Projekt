$domain = "project.local"
$UserName = "project.local\demo"
$Password = "Demo1234####" | ConvertTo-SecureString -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName,$Password

Add-Computer -DomainName $domain -DomainCredential $Credential -Restart -Verbose