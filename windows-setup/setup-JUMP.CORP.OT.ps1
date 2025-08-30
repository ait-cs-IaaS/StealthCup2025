using module ".\utils.psm1"

# group id configuration
$GroupID = "1" # the id specified here will be reflected in the ip addresses according to the ip address schema

# local account configuration
$LocalAccountPassword = "P@ssword1"
$LocalAccountUsername = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]

# machine configuration
$Hostname = "JUMP"

# network configuration
$Interface = (Get-NetAdapter -Name "$($settings.InterfacePrefix)*")[0].Name
$IpAddress = "10.$($GroupID)2.3.3"
$SubnetMask = "255.255.255.248"
$DefaultGateway = "10.$($GroupID)2.3.1"
$DnsServer = "10.$($GroupID)2.1.3"
$DnsServer2 = "8.8.8.8"

# active directory configuration
$Domain = "CORP.OT"
$DomainAccountUsername = "$Domain\Bob" # this domain user be used during setup; format: "CORP.OT\alice"
$DomainAccountPassword = "P@ssword"

$SetupScriptPath = $MyInvocation.MyCommand.Path

[Utils]::CheckPrivileges()
$Status = [Utils]::ReadStatus()
if ($Status -eq "") {
    [Utils]::ConfigureTimezone()
    [Utils]::EnableIcmpRequests()
    [Utils]::EnableRdp()
    [Utils]::ConfigureNetworkInterface($Interface, $IpAddress, $SubnetMask, $DefaultGateway, $DnsServer, $DnsServer2)
    [Utils]::ChangePassword($LocalAccountUsername, $LocalAccountPassword)
    [Utils]::ChangeHostname($Hostname) # requires reboot
    [Utils]::EnableAutoLogon($LocalAccountUsername, $LocalAccountPassword)
    [Utils]::CreateScheduledSetupTask($SetupScriptPath, $LocalAccountUsername)
    [Utils]::WriteStatus("1")
    [Utils]::Reboot()
} elseif ($Status -eq "1") {
    # Disable-NetAdapter -Name "Internet" -Confirm:$false # vm only
    [Utils]::JoinDomain($Domain, $DomainAccountUsername, $DomainAccountPassword) # requires reboot
    # Enable-NetAdapter -Name "Internet" -Confirm:$false # vm only
    [Utils]::WriteStatus("2")
    [Utils]::Reboot()
} elseif ($Status -eq "2") {
    [Utils]::Login($DomainAccountUsername, $DomainAccountPassword)
    [Utils]::AddToLocalGroup($DomainAccountUsername, "Administrators") # might remove group membership at end of setup
    [Utils]::EnableAutoLogon($DomainAccountUsername, $DomainAccountPassword) # reboot to login as domain user
    [Utils]::RemoveScheduledSetupTask()
    [Utils]::CreateScheduledSetupTask($SetupScriptPath, $DomainAccountUsername)
    [Utils]::WriteStatus("10")
    [Utils]::Reboot()
} elseif ($Status -eq "10") {
    [Utils]::RemoveScheduledSetupTask()
    [Utils]::DisableAutoLogon()
    [Utils]::RemoveStatus()

    Write-Host "[+] All done." -ForegroundColor Green -BackgroundColor Black
    pause
}
