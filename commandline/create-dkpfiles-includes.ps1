function createlog($logfilepath){
    if($(test-path $logfilepath)){
        remove-item $logfilepath -Force
        "" | Out-File -NoNewline $logfilepath
    }
}

function logit($logline, $logfilepath){
    $(get-date -Format o) + " " + $logline | Out-File $logfilepath -Append
    "[*] To Audit Log: $logline" | Write-Host -ForegroundColor Yellow
}