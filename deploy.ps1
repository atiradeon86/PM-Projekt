
$Title = 'Bryan Deplyoment Solutions - Always Look on the Bright Side of Life ... '

    Clear-Host
    Write-Host "======= $Title =======`r`n" -ForegroundColor Green
    
    Write-Host "1: Press '1' for Deploy DC1"
    Write-Host "2: Press '2' for Deploy FS1"
    Write-Host "3: Press '3' for Deploy W10Client (21H2-Pro)"
    Write-Host "4: Press '4' for Deploy W11Client (21H2-Pro)"
    Write-Host "5: Press '5' for Auto Deploy`r`n" -ForegroundColor Red
    Write-Host "Q: Press 'Q' to quit.`r`n"

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
        ./04.ps1
     } '5' {
      ./auto_deploy.ps1
     }
     'q' {
         return
     }
 }

