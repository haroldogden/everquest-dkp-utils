param($guildfile, $raidfile, [switch]$debug=$false)
$logfile = $($(ls $raidfile | select -first 1)[0].Directory.FullName) + "\audit.txt"
$outfile = $raidfile.replace("RaidRoster", "dkpimport")

if($(test-path $outfile) -eq $true){
    Remove-Item $outfile
}

$guildcharacters = @{}
#$offlineguilddump = @{} # debug
$raidcharacters = @()
$characterzones = @{}
$altsbutnotmains = @()
$altsandtheirmain = @{}
$altsaddedtoattendance = @()
$guildlookup = @{}
$debug = $false

. ..\commandline\create-dkpfiles-includes.ps1

logit -logline "raidfile: $raidfile" -logfilepath $logfile
logit -logline "guildfile: $guildfile" -logfilepath $logfile

##############################################################################

# build out all of the data structures we will need to evaluate our test cases

# first is a dictionary of characters, with the key being the character name and the value a list of the character's guild attributes that we will need to determine main/alt, etc.

get-content $guildfile | % {
    $guildcharacters[$_.Split("`t")[0]] = $_.Split("`t")[1..8]
}


# and an array containing arrays of character information for those who were in the raid

get-content $raidfile | % {
    $raidcharacters += $_.Split("`t")[1]
}

# slim things down so we only have mains to worry about for future logic
# build a dictionary of mains' names. The values are lists of dictionaries. Any time we see an alt and it resolves to that main, add a new dictionary to that main character's list with Zone: {zone} and InDZ: {True/False}

$originalraidcharactercount = $raidcharacters.Count
foreach($thischaracter in $raidcharacters){

    # for alts
    if($guildcharacters.ContainsKey($thischaracter) -eq $false){
        $raidcharacters = $raidcharacters | ?{$_ -ne $thischaracter}
        logit -logline ("Exception: " + $thischaracter + " was in the raid dump but not in the guild dump") -logfilepath $logfile
    }
    elseif($guildcharacters[$thischaracter][6] -match "(?s)([a-zA-Z]+) is main"){
        "[+] Found alt: " | write-host -ForegroundColor Yellow -NoNewline
        $thismain = $matches[1]
        $thischaracter + " is alt of " + $thismain | Write-Host -ForegroundColor Cyan
        # remove the alt if the main is in the raid
        if($thismain -in $raidcharacters){
            "`t" + "[+] "+ "Removing alt, main is present for " + $thischaracter
            if($characterzones[$thismain]){
                $characterzones[$thismain] += $guildcharacters[$thischaracter][5]
            }
            else{
                $characterzones[$thismain] = @($guildcharacters[$thischaracter][5])
            }
            $raidcharacters = $raidcharacters | ?{$_ -ne $thischaracter}
        }
        # alt is in the raid but not the main. 
        elseif($thismain -notin $raidcharacters){
            $raidcharacters = $raidcharacters | ?{$_ -ne $thischaracter}
            $altsbutnotmains += $thismain
            $altsandtheirmain[$thischaracter] = $thismain
            if($characterzones[$thismain]){
                $characterzones[$thismain] += $guildcharacters[$thischaracter][5]
            }
            else{
                $characterzones[$thismain] = @($guildcharacters[$thischaracter][5])
            }
        }
    }
    elseif($thischaracter -notmatch "(?s)([a-zA-Z]+) is main"){
        if($characterzones[$thischaracter]){
            if($debug -eq $true){
                $thischaracter + " already has an array of zones, adding to it" | Write-Host -ForegroundColor Green
            }
            $characterzones[$thischaracter] += $guildcharacters[$thischaracter][5]
        }
        else{
            if($debug -eq $true){
                $thischaracter + " did not have an array of zones, creating one" | Write-Host -ForegroundColor Green
            }
            $characterzones[$thischaracter] = @($guildcharacters[$thischaracter][5])
        }
    }
}
$raidcharacters.Count

foreach($i in $(get-content $guildfile | %{$_.Split("`t")[6]} | ?{$_ -notmatch "OFFLINE" -and  $_.Length -gt 5} |Group-Object | Sort-Object Count -Descending)){
    $i.Name + " has " + $i.Count + " players - is this the raid zone?"
    $answer = Read-Host "Y or N"
    if($answer -imatch "y"){
        $raidzone = $i.Name
        break
    }
}

foreach($i in $raidcharacters){
    if($raidzone -in $characterzones[$i]){
        if($debug){
            "[+] " + $i + " is in zone " + $raidzone | Write-Host -ForegroundColor Cyan
        }
    }
    else{
        $i + " is NOT in zone " + $raidzone + ". They are in zone(s) " + $characterzones[$i] + ":: should they get dkp?" | Write-Host -ForegroundColor Yellow
        if($(Read-Host "Y or N") -imatch "n"){
            $raidcharacters = $raidcharacters | ?{$_ -ne $i}
            logit -logline $($i + " has been removed from attendance") -logfilepath $logfile
        }
    }
}

foreach($i in $altsbutnotmains){
    if($raidzone -in $characterzones[$i]){
        $i + " is only present on an ALT and is in zone " + $raidzone | Write-Host -ForegroundColor Cyan
    }
    else{
        $i + " is NOT in zone " + $raidzone + ". They are in zone(s) " + $characterzones[$i] + ":: should they get dkp?" | Write-Host -ForegroundColor Yellow
        if($(Read-Host "Y or N") -imatch "n"){
            $raidcharacters = $raidcharacters | ?{$_ -ne $i}
        }
    }
}

foreach($line in $(get-content $raidfile)){
    $splitline = $line.split("`t")
    if($splitline[1] -in $raidcharacters){
        $splitline[0..7] -join "`t" | Out-File -Append $outfile
    }
    elseif($altsandtheirmain.ContainsKey($splitline[1])){
        if($altsandtheirmain[$splitline[1]] -in $altsaddedtoattendance){
            "Alt found, but " + $altsandtheirmain[$splitline[1]] + " already counted for attendance - skipping..."
        }
        else{
            $altsaddedtoattendance += $altsandtheirmain[$splitline[1]]
            $temp = $splitline
            $temp[1] = $altsandtheirmain[$splitline[1]]
            $temp[2] = $guildcharacters[$temp[1]][0]
            $temp[3] = $guildcharacters[$temp[1]][1]
            logit -logline $("only on alt: " + $temp[1]) -logfilepath $logfile
            $temp[0..7] -join "`t" | Out-File -Append $outfile
        }
    }
}