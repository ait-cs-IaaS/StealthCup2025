using module ".\utils.psm1"

param (
    [Parameter(Mandatory=$true)] $ConfigurationFile,
    [Parameter(Mandatory=$true)] $InventoryFile
)

if (-Not (Test-Path $ConfigurationFile)) {
    Write-Host "[!] The configuration file at '$ConfigurationFile' was not found" -ForegroundColor Red -BackgroundColor Black
    exit
}

if (-Not (Test-Path $InventoryFile)) {
    Write-Host "[!] The inventory file at '$InventoryFile' was not found" -ForegroundColor Red -BackgroundColor Black
    exit
}

$HostID = "enterprise_domain_controller"
$Configuration = Get-Content $ConfigurationFile | ConvertFrom-JSON
$HostConfiguration = $Configuration.WindowsHosts | Where-Object { $_.HostID -eq $HostID }
if ($HostConfiguration.PSObject.Properties.Name -contains "DCHostID") {
    $DCHostID = $HostConfiguration.DCHostID
    $IsDC = $false
} else {
    $DCHostID = $HostID
    $IsDC = $true
}
$DomainConfiguration = $Configuration.Domains | Where-Object { $_.HostID -eq $DCHostID }
$Inventory = Get-Content $InventoryFile | ConvertFrom-JSON

# local account configuration
$LocalAccountPassword = $HostConfiguration.LocalAccountPassword
$LocalAccountUsername = $HostConfiguration.LocalAccountUsername

# machine configuration
$Hostname = $HostConfiguration.Hostname

# network configuration
$Interface = (Get-NetAdapter)[0].Name
if (-not $IsDC) {
    $DNS1 = $Inventory.$DCHostID
} else {
    $DNS1 = "127.0.0.1"
}
$DNS2 = "8.8.8.8"

# active directory configuration
$Domain = $DomainConfiguration.Domain
$DomainAccountUsername = "$Domain\$LocalAccountUsername" # format: PLUMETECH.LOCAL\alice
$DomainAccountPassword = $LocalAccountPassword
$DsrmPassword = $DomainConfiguration.DsrmPassword

# domain users
$DomainUsers = $DomainConfiguration.DomainUsers

# GenericAll access to machines
$GenericAllAccessUsers = $HostConfiguration.GenericAllAccessUsers

# dns forwarding
$DNSForwarderHostID = $HostConfiguration.DNSForwarderHostID
$DnsForwarderRemoteDomainConfiguration = $Configuration.Domains | Where-Object { $_.HostID -eq $DNSForwarderHostID }
$DnsForwarderRemoteDomain = $DnsForwarderRemoteDomainConfiguration.Domain
$DnsForwarderRemoteDcIp = $Inventory.$DNSForwarderHostID

$SetupScriptPath = $MyInvocation.MyCommand.Path

try {
    # [Utils]::StartTranscript()
    [Utils]::CheckPrivileges()
    $Status = [Utils]::ReadStatus()
    if ($Status -eq "") {
        [Utils]::ConfigureTimezone()
        [Utils]::EnableIcmpRequests()
        [Utils]::EnableRdp()
        [Utils]::ConfigureNetworkInterface($Interface, $DNS1, $DNS2)
        [Utils]::ChangePassword($LocalAccountUsername, $LocalAccountPassword)
        [Utils]::ChangeHostname($Hostname) # requires reboot
        [Utils]::WriteStatus("1")
    } elseif ($Status -eq "1") {
        [Utils]::InstallActiveDirectoryDomainServices($Domain, $DsrmPassword) # requires reboot
        [Utils]::ConfigureNetworkInterface($Interface, $DNS1, $DNS2)
        [Utils]::WriteStatus("2")
    } elseif ($Status -eq "2") {
        [Utils]::WeakenPasswordPolicy($Domain)
        [Utils]::CreateDomainUsers($DomainUsers)
        [Utils]::ConfigureGenericAllAccess($GenericAllAccessUsers, $Hostname)
        [Utils]::InstallActiveDirectoryCertificateServices()
        [Utils]::InstallADCSWebEnrollment()
        [Utils]::ConfigureDnsForwarder($DnsForwarderRemoteDomain, $DnsForwarderRemoteDcIp)
        [Utils]::RemoveStatus()
        Write-Host "[+] All done." -ForegroundColor Green -BackgroundColor Black
    }
    # [Utils]::StopTranscript()
} catch {
    Write-Host "[!] An error occurred: $_" -ForegroundColor Red
    Write-Host "[!] Stack Trace: $($_.Exception.StackTrace)" -ForegroundColor Yellow
}