function createlog($logfilepath){
    if($(test-path $logfilepath)){
        remove-item $logfilepath -Force
        "" | Out-File -NoNewline $logfilepath
    }
}

function logit($logline, $logfilepath){
    $logline | Out-File $logfilepath -Append
    "[*] To Audit Log: $logline" | Write-Host -ForegroundColor Yellow
}