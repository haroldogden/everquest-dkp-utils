param($directorywithlogs)

cd $PSScriptRoot

if($directorywithlogs){
    "Looking in $directorywithlogs for RaidRoster files..." | Write-Host
}
else{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.rootfolder = "MyComputer"

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder += $foldername.SelectedPath
    }
    $directorywithlogs = $folder
}

$raidfiles = ls $directorywithlogs\RaidRoster-*.txt

if($raidfiles){
    foreach($raidfile in $raidfiles){
        "Processing raid file: " + $raidfile.Name | Write-Host -ForegroundColor Green
        $thisfiledate = $raidfile.Name.Split("-")[1]
        $thisfiletimeprefix = $raidfile.Name.Split("-")[2][0,1,2] -join ""
        $thisguildfile = ls $directorywithlogs\Divinitas-$thisfiledate-$thisfiletimeprefix*.txt
        if($thisguildfile.count -eq 1){
            "Paired raid file with guild file: " + $thisguildfile.Name | Write-Host -ForegroundColor Green
            .\create-dkpfiles.ps1 -guildfile $thisguildfile.FullName -raidfile $raidfile.FullName
        }
        elseif($thisguildfile.count -gt 1){
        "ERROR: Too many files matched..." | Write-Host -ForegroundColor Yellow
        $raidfile.Name + " appears to be in the same 10 minutes as the following files..." | Write-Host -ForegroundColor Yellow
            foreach($i in $thisguildfile){
                "--" + $i.Name | write-host -ForegroundColor Yellow
            }
        }
        else{
            "ERROR: No many files matched file " + $raidfile.Name | write-host -ForegroundColor Yellow
        }
    }
}
else{
    "No raid files found" | write-host -foregroundcolor Red
}

Read-Host "Script complete. Press Enter to quit..."