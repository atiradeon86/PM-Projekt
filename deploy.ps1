
$Title = 'PM-Projekt Deplyoment - Always Look on the Bright Side of Life ... '

    Clear-Host
    Write-Host "======= $Title =======" 
    
    Write-Host "1: Press '1' for Deploy DC1"
    Write-Host "2: Press '2' for Deploy FS1"
    Write-Host "3: Press '3' for Deploy W10Client"
    Write-Host "4: Press '4' for Auto Deploy"
    Write-Host "Q: Press 'Q' to quit."

$menu = Read-Host "What you want to do?"

switch ($menu)
 {
     '1' {
        ./01.ps1
     } '2' {
        ./02.ps1
     } '3' {
        ./03.ps1
     } '4' {
        ./auto_deploy.ps1
     }  'q' {
         return
     }
 }

