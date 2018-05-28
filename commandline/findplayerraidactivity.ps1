param($playername, $logfile)


if($playername){
    "[+] " + $playername + " has been selected." | Write-Host
}
else{
    $playername = Read-host "Provide a player name to search for:"
}

if($logfile){
    "[+] Searching $logfile for who results..." | Write-Host
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

findstr /R /C:"$playername.*raid\.$" $logfile

Read-Host "Script Complete. Press enter to close..."