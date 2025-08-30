using module ".\utils.psm1"

if (Test-Path ./settings.json) {
	$settings = Get-Content ./settings.json | ConvertFrom-JSON
} else {
	Write-Host "[-] Settings.json not found, aborting ..." -ForegroundColor Red -BackgroundColor Black
	Exit
}

# group id configuration
$GroupID = $settings.groupID # the id specified here will be reflected in the ip addresses according to the ip address schema

# local account configuration
$LocalAccountPassword = $settings.OTDCLocalAdminPwd
$LocalAccountUsername = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]

# machine configuration
$Hostname = $settings.OTDCHostname

# network configuration
$Interface = (Get-NetAdapter -Name "$($settings.InterfacePrefix)*")[0].Name
$IpAddress = "10.$($GroupID)2.1.3"
$SubnetMask = "255.255.255.248"
$DefaultGateway = "10.$($GroupID)2.1.1"
$DnsServer = "127.0.0.1"
$DnsServer2 = "8.8.8.8"

# active directory configuration
$Domain = $settings.OTDomainName
$DomainAccountUsername = "$Domain\$LocalAccountUsername" # format: CORP.LOCAL\alice
$DomainAccountPassword = $LocalAccountPassword
$DsrmPassword = $settings.OTDSRMPwd

# domain users
$DomainUsers = @()
$DomainUsers += [PSCustomObject]@{ Username = "$Domain\Bob"; Password = "P@ssword"; IsDomainAdmin = $true } # username format: "CORP.LOCAL\alice"
$DomainUsers += [PSCustomObject]@{ Username = "$Domain\John"; Password = "P@ssword"; IsDomainAdmin = $false }

# dns forwarding
$DnsForwarderRemoteDomain = $settings.CorpDomainName
$DnsForwarderRemoteDcIp = "10.$($GroupID)1.1.3"

# domain trust
$TrustingRemoteDomain = $settings.CorpDomainName
$TrustingRemoteAdminUsername = "$TrustingRemoteDomain\Administrator" # format: "CORP.LOCAL\Administrator"
$TrustingRemoteAdminPassword = $settings.CorpDomainAdminPwd

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
    [Utils]::ConfigureNetworkInterface($Interface, $IpAddress, $SubnetMask, $DefaultGateway, $DnsServer, $DnsServer2)
    [Utils]::InstallActiveDirectoryDomainServices($Domain, $DsrmPassword) # requires reboot
    # netsh interface ipv4 set dns name="Internet" static 8.8.8.8 # vm only
    [Utils]::WriteStatus("2")
    [Utils]::Reboot()
} elseif ($Status -eq "2") {
    [Utils]::CreateDomainUsers($DomainUsers)
    [Utils]::ConfigureDnsForwarder($DnsForwarderRemoteDomain, $DnsForwarderRemoteDcIp)
    [Utils]::ConfigureBidirectionalDomainTrust($TrustingRemoteDomain, $TrustingRemoteAdminUsername, $TrustingRemoteAdminPassword)
    [Utils]::WriteStatus("10")
    [Utils]::Reboot()
} elseif ($Status -eq "10") {
    [Utils]::RemoveScheduledSetupTask()
    [Utils]::DisableAutoLogon()
    [Utils]::RemoveStatus()

    Write-Host "[+] All done." -ForegroundColor Green -BackgroundColor Black
    pause
}
