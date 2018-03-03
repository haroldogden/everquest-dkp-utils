param($logfile)

"[!] Please select your log file..."

if($logfile){
    "[+] Searching $logfile for auction results..." | Write-Host
}
else{
 [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
 Out-Null

 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 $OpenFileDialog.initialDirectory = $initialDirectory
 $OpenFileDialog.filter = "All files (*.*)| *.*"
 $OpenFileDialog.ShowDialog() | Out-Null
 $logfile = $OpenFileDialog.filename
}

& findstr /i /C:"auction result" $logfile
"" | Write-Host
read-host "[+] Script Complete. Press enter to exit..."