class Utils {
    Static [Void] CheckPrivileges() {
        if (-not (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
            Write-Host "[!] Script needs to be run with administrator privileges. Exiting ..." -ForegroundColor Red -BackgroundColor Black
            pause
            exit
        }
    }

    Static [Void] ConfigureNetworkInterface($Interface, $IpAddress, $SubnetMask, $DefaultGateway, $DnsServer, $DnsServer2) {
        Write-Host "[*] Configuring network interface $Interface ..." -ForegroundColor Yellow -BackgroundColor Black
        netsh interface ipv4 set address name=$Interface static $IpAddress $SubnetMask $DefaultGateway
        netsh interface ipv4 set dns name=$Interface static $DnsServer
        netsh interface ipv4 add dns name=$Interface $DnsServer2 index=2
    }

    Static [Void] ChangePassword($Username, $Password) {
        Write-Host "[*] Changing password of $Username ..." -ForegroundColor Yellow -BackgroundColor Black
        Set-LocalUser -Name $Username -Password (ConvertTo-SecureString $Password -AsPlainText -Force)
    }

    Static [Void] ChangeHostname($Hostname) {
        Write-Host "[*] Changing hostname ..." -ForegroundColor Yellow -BackgroundColor Black
        Rename-Computer -NewName $Hostname -Force
    }

    Static [Void] InstallActiveDirectoryDomainServices($Domain, $DsrmPassword) {
        Write-Host "[*] Installing the active directory domain services ..." -ForegroundColor Yellow -BackgroundColor Black
        Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
        Install-ADDSForest -DomainName $Domain -SafeModeAdministratorPassword (ConvertTo-SecureString $DsrmPassword -AsPlainText -Force) -Force -NoRebootOnCompletion
    }

    Static [Void] InstallActiveDirectoryCertificateServices() {
        Write-Host "[*] Installing the active directory certificate services ..." -ForegroundColor Yellow -BackgroundColor Black
        Install-WindowsFeature Adcs-Cert-Authority -IncludeManagementTools
        Install-AdcsCertificationAuthority -CAType EnterpriseRootCa -Force
    }

    Static [Void] InstallADCSWebEnrollment() {
        Write-Host "[*] Installing the adcs web enrollment ..." -ForegroundColor Yellow -BackgroundColor Black
        Add-WindowsFeature Adcs-Web-Enrollment
        Install-AdcsWebEnrollment -Force
    }

    Static [Void] Reboot() {
        Write-Host "[*] Rebooting ..." -ForegroundColor Yellow -BackgroundColor Black
        pause
        Restart-Computer
    }

    Static [Void] EnableAutoLogon($Username, $Password) {
        Write-Host "[*] Enabling auto logon for $Username ..." -ForegroundColor Yellow -BackgroundColor Black
        if ($Username -like "*\*") {
            $Domain = $Username.Split('\')[0]
            $Username = $Username.Split('\')[-1]
            [Utils]::WriteRegistryKey("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultDomainName", $Domain)

        }
        [Utils]::WriteRegistryKey("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultUserName", $Username)
        [Utils]::WriteRegistryKey("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultPassword", $Password)
        [Utils]::WriteRegistryKey("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "AutoAdminLogon", "1")
    }

    Static [Void] DisableAutoLogon() {
        Write-Host "[*] Disabling auto logon ..." -ForegroundColor Yellow -BackgroundColor Black
        [Utils]::RemoveRegistryKey("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultDomainName")
        [Utils]::RemoveRegistryKey("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultUserName")
        [Utils]::RemoveRegistryKey("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultPassword")
        [Utils]::RemoveRegistryKey("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "AutoAdminLogon")
    }

    Static [String] ReadStatus() {
        return [Utils]::ReadRegistryKey("HKLM:\SOFTWARE\TestCat", "Status")
    }

    Static [Void] WriteStatus($Status) {
        [Utils]::WriteRegistryKey("HKLM:\SOFTWARE\TestCat", "Status", $Status)
    }

    Static [Void] RemoveStatus() {
        [Utils]::RemoveRegistryKey("HKLM:\SOFTWARE\TestCat", "Status")
    }

    Static [String] ReadRegistryKey($Path, $Key) {
        Write-Host "[*] Reading from registry $Path\$Key ..." -ForegroundColor Yellow -BackgroundColor Black
        if (-not (Test-Path $Path)) {
            return ""
        }
        return (Get-ItemProperty -Path $Path).$Key
    }

    Static [Void] WriteRegistryKey($Path, $Key, $Value) {
        Write-Host "[*] Writing $Value to registry $Path\$Key" -ForegroundColor Yellow -BackgroundColor Black

        # if the path does not exist, create the path
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path
        }

        # if the key does not exist, create the key and set the value
        if (-not (Get-ItemProperty -Path $Path -Name $Key -ErrorAction SilentlyContinue)) {
            New-ItemProperty -Path $Path -Name $Key -Value $Value
        }

        # if the key already exists, just update the value
        else {
            Set-ItemProperty -Path $Path -Name $Key -Value $Value
        }
    }

    Static [Void] RemoveRegistryKey($Path, $Key) {
        Write-Host "[*] Removing from registry $Path\$Key ..." -ForegroundColor Yellow -BackgroundColor Black
        Remove-ItemProperty -Path $Path -Name $Key
    }

    Static [Void] CreateScheduledSetupTask($SetupScriptPath, $Username) {
        Write-Host "[*] Creating scheduled setup task for $Username ..." -ForegroundColor Yellow -BackgroundColor Black
        $Action = New-ScheduledTaskAction -Execute "powershell" -Argument "-ExecutionPolicy Bypass -File $SetupScriptPath" -WorkingDirectory $PSScriptRoot
        $Trigger = New-ScheduledTaskTrigger -AtLogOn -User $Username
        Register-ScheduledTask -Action $Action -Trigger $Trigger -User $Username -TaskName "TestCatSetup" -RunLevel Highest
    }

    static [void] CreateScheduledNTLMTask($Hostname, $Interval, $Username) {
        Write-Host "[*] Creating scheduled NTLM task for $Username ..." -ForegroundColor Yellow -BackgroundColor Black
        $Command = "New-SMBMapping -RemotePath \\$Hostname"
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command $Command"
        $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $Interval)
        Register-ScheduledTask -Action $Action -Trigger $Trigger -User $Username -TaskName "TestCatNTLM" -RunLevel Highest
    }

    Static [Void] RemoveScheduledSetupTask() {
        Write-Host "[*] Removing scheduled setup task ..." -ForegroundColor Yellow -BackgroundColor Black
        Unregister-ScheduledTask -TaskName "TestCatSetup" -Confirm:$false
    }

    Static [Void] EnableIcmpRequests() {
        Write-Host "[*] Enabling icmp requests ..." -ForegroundColor Yellow -BackgroundColor Black
        netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes
    }

    Static [Void] ConfigureTimezone() {
        Write-Host "[*] Configuring timezone ..." -ForegroundColor Yellow -BackgroundColor Black
        Set-TimeZone -Id "W. Europe Standard Time"
    }

    Static [Void] EnableRdp() {
        Write-Host "[*] Enabling rdp ..." -ForegroundColor Yellow -BackgroundColor Black
        [Utils]::WriteRegistryKey("HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server", "fDenyTSConnections", "0")
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    }

    Static [Void] JoinDomain($Domain, $DomainAccountUsername, $DomainAccountPassword) {
        Write-Host "[*] Joining domain $Domain ..." -ForegroundColor Yellow -BackgroundColor Black
        $Credential = [Utils]::GetCredential($DomainAccountUsername, $DomainAccountPassword)
        Add-Computer -DomainName $Domain -Credential $Credential -Force
    }

    Static [SecureString] GetSecurePassword($Password) {
        return ConvertTo-SecureString $Password -AsPlainText -Force
    }

    Static [PSCredential] GetCredential($Username, $Password) {
        return New-Object System.Management.Automation.PSCredential($Username, [Utils]::GetSecurePassword($Password))
    }

    Static [Void] Login($Username, $Password) {
        Write-Host "[*] Logging in as $Username ..." -ForegroundColor Yellow -BackgroundColor Black
        $Credential = [Utils]::GetCredential($Username, $Password)
        Start-Process powershell.exe -Wait -NoNewWindow -Credential $Credential -ArgumentList "-Command whoami"
    }

    Static [Void] AddToLocalGroup($Username, $Group) {
        Write-Host "[*] Adding $Username to local group $Group ..." -ForegroundColor Yellow -BackgroundColor Black
        Add-LocalGroupMember -Group $Group -Member $Username
    }

    Static [Void] AddToDomainGroup($Username, $Group) {
        Write-Host "[*] Adding $Username to domain group $Group ..." -ForegroundColor Yellow -BackgroundColor Black
        $Username = $Username.Split('\')[-1] # Add-ADGroupMember expects a username without prepended domain
        Add-ADGroupMember -Identity $Group -Members $Username
    }

    Static [Void] CreateDomainUser($Name, $SamAccountName, $UserPrincipalName, $SecurePassword) {
        Write-Host "[*] Creating domain user $SamAccountName ..." -ForegroundColor Yellow -BackgroundColor Black
        New-ADUser -Name $Name -SamAccountName $SamAccountName -UserPrincipalName $UserPrincipalName -AccountPassword $SecurePassword -Enabled $true -PasswordNeverExpires $true
    }

    Static [Void] CreateDomainUsers($DomainUsers) {
        foreach ($DomainUser in $DomainUsers) {
            $Domain = $DomainUser.Username.Split('\')[0] # username format: "enterprise.local\alice"
            $Name = $DomainUser.Username.Split('\')[-1]
            $SamAccountName = $Name.ToLower()
            $UserPrincipalName = "$($SamAccountName)@$($Domain)"
            $SecurePassword = [Utils]::GetSecurePassword($Domainuser.Password)
            [Utils]::CreateDomainUser($Name, $SamAccountName, $UserPrincipalName, $SecurePassword)
            if ($DomainUser.IsDomainAdmin) {
                [Utils]::AddToDomainGroup($DomainUser.Username, "Domain Admins")
            }
        }
    }

    Static [Void] HostFileshare($Name, $Path, $ReadAccessUsernames) {
        Write-Host "[*] Hosting fileshare $Name at $Path ..." -ForegroundColor Yellow -BackgroundColor Black
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -ItemType Directory
        }
        New-SmbShare -Name $Name -Path $Path -ReadAccess $ReadAccessUsernames
    }

    Static [Void] ConfigureDnsForwarder($RemoteDomain, $RemoteDcIp) {
        Write-Host "[*] Configuring conditional dns forwarder to $RemoteDomain ..." -ForegroundColor Yellow -BackgroundColor Black
        Add-DnsServerConditionalForwarderZone -Name $RemoteDomain -MasterServers $RemoteDcIp
    }

    Static [Void] ConfigureBidirectionalDomainTrust($RemoteDomain, $RemoteAdminUsername, $RemoteAdminPassword) {
        Write-Host "[*] Configuring bidirectional domain trust to $RemoteDomain ..." -ForegroundColor Yellow -BackgroundColor Black
        $remoteContext = New-Object -TypeName "System.DirectoryServices.ActiveDirectory.DirectoryContext" -ArgumentList @( "Forest", $RemoteDomain, $RemoteAdminUsername, $RemoteAdminPassword)
        $remoteForest = [System.DirectoryServices.ActiveDirectory.Forest]::getForest($remoteContext)
        $localforest=[System.DirectoryServices.ActiveDirectory.Forest]::getCurrentForest()
        $localForest.CreateTrustRelationship($remoteForest, "Bidirectional")
    }
}
