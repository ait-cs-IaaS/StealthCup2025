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

$HostID = "enterprise_file_server"
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
$DomainAccountUsername = $HostConfiguration.DomainAccountUsername # this domain user be used during setup; format: "PLUMETECH.LOCAL\alice"
$DomainAccountConfiguration = $DomainConfiguration.DomainUsers | Where-Object { $_.Username -eq $DomainAccountUsername }
$DomainAccountPassword = $DomainAccountConfiguration.Password

# fileshare configuration
$Fileshares = $HostConfiguration.Fileshares

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
        [Utils]::JoinDomain($Domain, $DomainAccountUsername, $DomainAccountPassword) # requires reboot
        [Utils]::WriteStatus("2")
    } elseif ($Status -eq "2") {
        [Utils]::Login($DomainAccountUsername, $DomainAccountPassword)
        [Utils]::AddToLocalGroup($DomainAccountUsername, "Administrators") # might remove group membership at end of setup
        [Utils]::WriteStatus("3")
    } elseif ($Status -eq "3") {
        [Utils]::HostFileshares($Fileshares)
        [Utils]::HostIisWebserver()
        [Utils]::RemoveStatus()
        Write-Host "[+] All done." -ForegroundColor Green -BackgroundColor Black
    }
    # [Utils]::StopTranscript()
} catch {
    Write-Host "[!] An error occurred: $_" -ForegroundColor Red
    Write-Host "[!] Stack Trace: $($_.Exception.StackTrace)" -ForegroundColor Yellow
}