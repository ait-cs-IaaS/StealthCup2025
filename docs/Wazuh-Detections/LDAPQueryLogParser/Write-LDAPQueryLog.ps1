Add-Content -Path "C:\ProgramData\AIT\LDAPQueryLogParserExecution-$((Get-Date).toString("yyyyMMdd")).log" -Value "$((get-Date).toString("[yyyy-MM-dd HH:mm:ss] "))Gather local IP addresses for filtering"

$addresses = @()
Foreach ($address in Get-NetIPAddress)
{
    Add-Content -Path "C:\ProgramData\AIT\LDAPQueryLogParserExecution-$((Get-Date).toString("yyyyMMdd")).log" -Value "$((get-Date).toString("[yyyy-MM-dd HH:mm:ss] "))$($address.IPAddress) $($address.AddressFamily)"
    if ($address.AddressFamily -eq 'IPv6')
    {
        $addresses += "["+$address.IPAddress+"]"
        Add-Content -Path "C:\ProgramData\AIT\LDAPQueryLogParserExecution-$((Get-Date).toString("yyyyMMdd")).log" -Value "$((get-Date).toString("[yyyy-MM-dd HH:mm:ss] "))adding to filter: [$($address.IPAddress)]"
    } else
    {
        $addresses += $address.IPAddress
        Add-Content -Path "C:\ProgramData\AIT\LDAPQueryLogParserExecution-$((Get-Date).toString("yyyyMMdd")).log" -Value "$((get-Date).toString("[yyyy-MM-dd HH:mm:ss] "))adding to filter: $($address.IPAddress)"
    }
}

# Known local query clients

$notaddress = ('Internal', 'KCC', 'LSA', 'NTDSAPI', 'SAM')

Add-Content -Path "C:\ProgramData\AIT\LDAPQueryLogParserExecution-$((Get-Date).toString("yyyyMMdd")).log" -Value "$((get-Date).toString("[yyyy-MM-dd HH:mm:ss] "))Done gathering local addresses"
Add-Content -Path "C:\ProgramData\AIT\LDAPQueryLogParserExecution-$((Get-Date).toString("yyyyMMdd")).log" -Value "$((get-Date).toString("[yyyy-MM-dd HH:mm:ss] "))Check if first run"
if (Test-Path HKLM:\SOFTWARE\AIT\LDAPQueryLogParser)
{
    $timespan = (Get-ItemProperty HKLM:\SOFTWARE\AIT\LDAPQueryLogParser -Name LastRun).LastRun
    Add-Content -Path "C:\ProgramData\AIT\LDAPQueryLogParserExecution-$((Get-Date).toString("yyyyMMdd")).log" -Value "$((get-Date).toString("[yyyy-MM-dd HH:mm:ss] "))Last Run: $(Get-Date($timespan))"
    Add-Content -Path "C:\ProgramData\AIT\LDAPQueryLogParserExecution-$((Get-Date).toString("yyyyMMdd")).log" -Value "$((get-Date).toString("[yyyy-MM-dd HH:mm:ss] "))Gathering LDAP Events (ID 1644) from Microsoft-Windows-ActiveDirectory_DomainService"
    $events = Get-winEvent @{ providername = 'Microsoft-Windows-ActiveDirectory_DomainService'; id = 1644; starttime = Get-Date($timespan)}
    Set-ItemProperty HKLM:\SOFTWARE\AIT\LDAPQueryLogParser -Name LastRun -Value (Get-Date).Ticks
} else
{
    Add-Content -Path "C:\ProgramData\AIT\LDAPQueryLogParserExecution-$((Get-Date).toString("yyyyMMdd")).log" -Value "$((get-Date).toString("[yyyy-MM-dd HH:mm:ss] "))First Run, setting Key in HKLM:\SOFTWARE\AIT\LDAPQueryLogParser"
    New-Item -Path HKLM:\SOFTWARE\AIT -Name LDAPQueryLogParser -Force
    Add-Content -Path "C:\ProgramData\AIT\LDAPQueryLogParserExecution-$((Get-Date).toString("yyyyMMdd")).log" -Value "$((get-Date).toString("[yyyy-MM-dd HH:mm:ss] "))Gathering LDAP Events (ID 1644) from Microsoft-Windows-ActiveDirectory_DomainService"
    $events = Get-winEvent @{ providername = 'Microsoft-Windows-ActiveDirectory_DomainService'; id = 1644}
    Set-ItemProperty HKLM:\SOFTWARE\AIT\LDAPQueryLogParser -Name LastRun -Value (Get-Date).Ticks
}
Add-Content -Path "C:\ProgramData\AIT\LDAPQueryLogParserExecution-$((Get-Date).toString("yyyyMMdd")).log" -Value "$((get-Date).toString("[yyyy-MM-dd HH:mm:ss] "))Event collection completed and LastRun Key updated"

$filterevents = $events | Where-Object {($_.properties[4].Value -notin $notaddress) -and (($_.properties[4].Value).substring(0,$_.properties[4].Value.lastIndexOf(':')) -notin $addresses)}

if ($filterevents) {
    Add-Content -Path "C:\ProgramData\AIT\LDAPQueryLogParserExecution-$((Get-Date).toString("yyyyMMdd")).log" -Value "$((get-Date).toString("[yyyy-MM-dd HH:mm:ss] "))Found $($filterevents.count) matching events"
    foreach ($event in $filterevents) {
         
        $notwritten = $true
        while ($notwritten) {
            try {
                    Add-content -Path C:\ProgramData\AIT\LDAPQueryLogParser-$((Get-Date).toString("yy-MM-dd")).log -Value "$($event.TimeCreated.toString("yyyy-MM-ddTHH:mm:ss.fffK")) $($event.MachineName) LDAPQueryLogParser: date=$($event.TimeCreated.toString("yyyy-MM-dd")) time=$($event.TimeCreated.toString("HH:mm:ss")) hostname=$($event.MachineName) srcip=$($event.properties[4].Value.substring(0,$event.properties[4].Value.lastIndexOf(':'))) win.eventdata.ipAddress=::ffff:$($event.properties[4].Value.substring(0,$event.properties[4].Value.lastIndexOf(':'))) srcport=$($event.properties[4].Value.substring($event.properties[4].Value.lastIndexOf(':')+1)) user=$($event.properties[16].Value) filter=""$($event.properties[1].Value.Trim() -replace '"', '''')"" scope=$($event.properties[5].Value) startingnode=$($event.properties[0].Value) attributeselection=$($event.properties[6].Value)" -ErrorAction Stop
                    $notwritten = $false
                } catch [System.IO.IOException]
                {
                    Add-Content -Path "C:\ProgramData\AIT\LDAPQueryLogParserExecution-$((Get-Date).toString("yyyyMMdd")).log" -Value "$((get-Date).toString("[yyyy-MM-dd HH:mm:ss] "))Trying to write to logfile C:\ProgramData\AIT\LDAPQueryLogParserExecution-$((Get-Date).toString("yyyyMMdd")).log, locked ..."
                    Start-Sleep -seconds 1

                }
        }
        Add-Content -Path "C:\ProgramData\AIT\LDAPQueryLogParserExecution-$((Get-Date).toString("yyyyMMdd")).log" -Value "$($event.TimeCreated.toString("yyyy-MM-ddTHH:mm:ss.fffK")) $($event.MachineName) LDAPQueryLogParser: date=$($event.TimeCreated.toString("yyyy-MM-dd")) time=$($event.TimeCreated.toString("HH:mm:ss")) hostname=$($event.MachineName) srcip=$($event.properties[4].Value.substring(0,$event.properties[4].Value.lastIndexOf(':'))) win.eventdata.ipAddress=::ffff:$($event.properties[4].Value.substring(0,$event.properties[4].Value.lastIndexOf(':'))) srcport=$($event.properties[4].Value.substring($event.properties[4].Value.lastIndexOf(':')+1)) user=$($event.properties[16].Value) filter=""$($event.properties[1].Value.Trim() -replace '"', '''')"" scope=$($event.properties[5].Value) startingnode=$($event.properties[0].Value) attributeselection=$($event.properties[6].Value)"
        
        
        

    }
} else {
    Add-Content -Path "C:\ProgramData\AIT\LDAPQueryLogParserExecution-$((Get-Date).toString("yyyyMMdd")).log" -Value "$((get-Date).toString("[yyyy-MM-dd HH:mm:ss] "))No matching Events found"
}
Add-Content -Path "C:\ProgramData\AIT\LDAPQueryLogParserExecution-$((Get-Date).toString("yyyyMMdd")).log" -Value "$((get-Date).toString("[yyyy-MM-dd HH:mm:ss] "))LDAPQueryLogParser finished successfully"
