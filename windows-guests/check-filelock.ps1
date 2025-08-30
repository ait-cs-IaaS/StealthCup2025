$notwritten = $true
while ($notwritten) {
    try {
            Add-content -Path C:\ProgramData\AIT\LDAPQueryLogParser-$((Get-Date).toString("yy-MM-dd")).log -Value " " -ErrorAction Stop
            $notwritten = $false
        } catch [System.IO.IOException]
        {
            Write-Host "File locked"
            Start-Sleep -seconds 1

            }
}
