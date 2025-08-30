class Utils {
    Static [Void] CheckPrivileges() {
        if (-not (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
            Write-Host "[!] Script needs to be run with administrator privileges. Exiting ..." -ForegroundColor Red -BackgroundColor Black
            exit
        }
    }

    Static [Void] ConfigureNetworkInterface($Interface, $DnsServer, $DnsServer2) {
        Write-Host "[*] Configuring network interface $Interface ..." -ForegroundColor Yellow -BackgroundColor Black
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
        return [Utils]::ReadRegistryKey("HKLM:\SOFTWARE\StealthCup", "Status")
    }

    Static [Void] WriteStatus($Status) {
        [Utils]::WriteRegistryKey("HKLM:\SOFTWARE\StealthCup", "Status", $Status)
    }

    Static [Void] RemoveStatus() {
        [Utils]::RemoveRegistryKey("HKLM:\SOFTWARE\StealthCup", "Status")
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

    static [void] CreateScheduledNTLMTask($Hostname, $Interval, $Username) {
        Write-Host "[*] Creating scheduled NTLM task for $Username ..." -ForegroundColor Yellow -BackgroundColor Black
        $Command = "New-SMBMapping -RemotePath \\$Hostname"
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command $Command"
        $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $Interval)
        Register-ScheduledTask -Action $Action -Trigger $Trigger -User $Username -TaskName "StealthCupNTLM" -RunLevel Highest
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
        # Start-Process powershell.exe -Wait -NoNewWindow -Credential $Credential -ArgumentList "-Command whoami"
        Start-Process C:\Windows\System32\WindowsPowershell\v1.0\powershell.exe -Wait -NoNewWindow -Credential $Credential -ArgumentList "-Command whoami"
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

    Static [Void] AddServicePrincipalName($Username, $ServicePrincipalName) {
        Write-Host "[*] Adding Service Principal Name $ServicePrincipalName to $Username ..." -ForegroundColor Yellow -BackgroundColor Black
        setspn -A $ServicePrincipalName $Username
    }

    Static [Void] DisablePreAuthentication($Username) {
        Write-Host "[*] Disabling pre-authentication for $Username ..." -ForegroundColor Yellow -BackgroundColor Black
        $Username = $Username.Split('\')[-1] # Set-ADAccountControl expects a username without prepended domain
        Set-ADAccountControl -Identity $Username -DoesNotRequirePreAuth $true
    }

    Static [Void] CreateDomainUser($Name, $SamAccountName, $UserPrincipalName, $SecurePassword, $Description) {
        Write-Host "[*] Creating domain user $SamAccountName ..." -ForegroundColor Yellow -BackgroundColor Black
        New-ADUser -Name $Name -SamAccountName $SamAccountName -UserPrincipalName $UserPrincipalName -AccountPassword $SecurePassword -Enabled $true -PasswordNeverExpires $true -Description $Description
    }

    Static [Void] CreateDomainUsers($DomainUsers) {
        foreach ($DomainUser in $DomainUsers) {
            $Domain = $DomainUser.Username.Split('\')[0] # username format: "enterprise.local\alice"
            $Name = $DomainUser.Username.Split('\')[-1]
            $SamAccountName = $Name.ToLower()
            $UserPrincipalName = "$($SamAccountName)@$($Domain)"
            $SecurePassword = [Utils]::GetSecurePassword($Domainuser.Password)
            $Description = $null
            if ($DomainUser.PSobject.Properties.Name.Contains("Description")) {
                $Description = $DomainUser.Description
            }
            [Utils]::CreateDomainUser($Name, $SamAccountName, $UserPrincipalName, $SecurePassword, $Description)
            if ($DomainUser.PSobject.Properties.Name.Contains("IsDomainAdmin") -and $DomainUser.IsDomainAdmin) {
                [Utils]::AddToDomainGroup($DomainUser.Username, "Domain Admins")
            }
            if ($DomainUser.PSobject.Properties.Name.Contains("HasPreAuthDisabled") -and $DomainUser.HasPreAuthDisabled) {
                [Utils]::DisablePreAuthentication($DomainUser.Username)
            }
            if ($DomainUser.PSobject.Properties.Name.Contains("ServicePrincipalName")) {
                [Utils]::AddServicePrincipalName($DomainUser.Username, $DomainUser.ServicePrincipalName)
            }
        }
    }

    Static [Void] ConfigureGenericAllAccess($GenericAllAccessUsers, $Hostname) {
        foreach ($GenericAllAccessUser in $GenericAllAccessUsers) {
            Write-Host "[*] Granting $($GenericAllAccessUser) GenericAll access to $Hostname ..." -ForegroundColor Yellow -BackgroundColor Black
            $dc = Get-ADComputer -Identity $Hostname
            $acl = Get-ACL -Path "AD:$($dc.DistinguishedName)"

            $identityReference = New-Object System.Security.Principal.NTAccount($GenericAllAccessUser)
            $accessRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
                $identityReference,
                [System.DirectoryServices.ActiveDirectoryRights]::GenericAll,
                [System.Security.AccessControl.AccessControlType]::Allow
            )

            $acl.AddAccessRule($accessRule)
            Set-ACL -Path "AD:$($dc.DistinguishedName)" -AclObject $acl
        }
    }

    Static [Void] HostFileshares($Fileshares) {
        foreach ($Fileshare in $Fileshares) {
            $Name = $Fileshare.Name
            $Path = $Fileshare.Path
            $Access = $Fileshare.Access
            Write-Host "[*] Hosting fileshare $Name at $Path ..." -ForegroundColor Yellow -BackgroundColor Black
            if (-not (Test-Path $Path)) {
                New-Item -Path $Path -ItemType Directory
            }
            New-SmbShare -Name $Name -Path $Path -FullAccess $Access
        }
    }

    Static [Void] HostIisWebserver() {
        Write-Host "[*] Hosting the IIS Webserver ..." -ForegroundColor Yellow -BackgroundColor Black
        Install-WindowsFeature Web-Server -IncludeManagementTools
        Remove-Website -Name "Default Web Site"
        Remove-Item -Path "C:\inetpub\wwwroot\*" -Recurse -Force
        if (-not (Test-Path "C:\inetpub\wwwroot")) {
            New-Item -Path "C:\inetpub\wwwroot" -ItemType Directory
        }
        New-Website -Name Website -PhysicalPath "C:\inetpub\wwwroot"
        Write-Output "Hello World!" > "C:\inetpub\wwwroot\index.html"
    }

    Static [Void] ConfigureDnsForwarder($RemoteDomain, $RemoteDcIp) {
        Write-Host "[*] Configuring conditional DNS forwarder to $RemoteDomain ..." -ForegroundColor Yellow -BackgroundColor Black
        Add-DnsServerConditionalForwarderZone -Name $RemoteDomain -MasterServers $RemoteDcIp
    }

    Static [Void] UpdateDnsForwarder($RemoteDomain, $RemoteDcIp) {
        Write-Host "[*] Updating conditional DNS forwarder to $RemoteDomain ..." -ForegroundColor Yellow -BackgroundColor Black
        Set-DnsServerConditionalForwarderZone -Name $RemoteDomain -MasterServers $RemoteDcIp
    }

    Static [Void] ConfigureBidirectionalDomainTrust($RemoteDomain, $RemoteAdminUsername, $RemoteAdminPassword) {
        Write-Host "[*] Configuring bidirectional domain trust to $RemoteDomain ..." -ForegroundColor Yellow -BackgroundColor Black
        $remoteContext = New-Object -TypeName "System.DirectoryServices.ActiveDirectory.DirectoryContext" -ArgumentList @( "Forest", $RemoteDomain, $RemoteAdminUsername, $RemoteAdminPassword)
        $remoteForest = [System.DirectoryServices.ActiveDirectory.Forest]::getForest($remoteContext)
        $localforest=[System.DirectoryServices.ActiveDirectory.Forest]::getCurrentForest()
        $localForest.CreateTrustRelationship($remoteForest, "Bidirectional")
    }

    Static [Void] GrantRdpAccess($RdpAccessUsernames) {
        foreach ($RdpAccessUsername in $RdpAccessUsernames) {
            Write-Host "[*] Granting $RdpAccessUsername RDP access ..." -ForegroundColor Yellow -BackgroundColor Black
            Add-LocalGroupMember -Group "Remote Desktop Users" -Member "$RdpAccessUsername"
        }
    }

    Static [Void] WeakenPasswordPolicy($Domain) {
        Write-Host "[*] Weakening the password policy ..." -ForegroundColor Yellow -BackgroundColor Black
        Set-ADDefaultDomainPasswordPolicy -Identity $Domain -ComplexityEnabled $false -MinPasswordLength 3
    }

    Static [Void] StartTranscript() {
        Write-Host "[*] Starting transcript ..." -ForegroundColor Yellow -BackgroundColor Black
        Start-Transcript -Path "C:\Windows\Temp\StealthCupSetup.log" -Append
    }

    Static [Void] StopTranscript() {
        Write-Host "[*] Stopping transcript ..." -ForegroundColor Yellow -BackgroundColor Black
        Stop-Transcript
    }
}
