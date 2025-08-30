# AV1: Initial Access
Ideas:
* Scenario 1: VPN access, the access file from the VPN is located in an external cloud solution and is accidentally discovered by a hacker. (password leak, private nextcloud/icloud/onedrive)
  * Problem: Layer 2 attacks are not possible
* Scenario 2: Implant (Linux host) attached to the client network via LTE
* Scenario 3: Vulnerable web server in the enterprise network

Scenario 2 is implemented. Starting point: hacker has full access to client network via KALI Linux ("**implant**").

This enables LLMNR poisoning with Windows client network.

**implant** access to Windows clients LLMNR traffic, hash of user is tapped (cannot be cracked), pass-the-hash ESC8 for certificate and via this access to file server access.

# AV2: User access in the Enterprise network using LLMNR spoofing and relaying of NTLMv2 authentication to Certificate Authority web enrollment service

* T1: The attacker's implant is on the same subnet and thereby broadcast domain as the enterprise client 
* T2: On the enterprise client a user with minimal domain privileges is logged on
* T3: The logged on user automatically tries to map an SMB share of a machine that's not found on the domain due to a typing error in the hostname (e.g. fielserver)
* T4: Since the machine can't be found in DNS nor hosts, an LLMNR broadcast is sent, which gets intercepted by the attacker and a spoofed reply is sent
* T5: The attacker-controlled NTLMv2 authentication flow is redirected (relayed) to the certification authority and a user certificate request issued
* T4: The compromised user has minimal permissions on the domain (probably can write something in AD -> TODO)

# AV3: User access in the Enterprise network by brute forcing kerberos authentication

* T1: The attacker's implant is routable to the fileserver and domain controller
* T2: The fileserver offers an ftp share with anonymous access which holds a list of domain usernames
* T3: The found username list can further be used to brute force credentials against the domain controller using kerberos
* T4: The only brute forcable user has minimal permissions on the domain (probably can write something in AD -> TODO)

# AV4: Lateral movement by finding clear text credentials on file share

* T1: Impersonating a normal domain user, the attacker scans for file shares and interesting files
* T2: Credentials to a user with domain administrator rights are found
* T3: Credentials to a user with RDP logon rights on the OT Jumphost are found

# AV5: Lateral movement by abusing Owner permission of compromised user on domain controller object

* T1: Impersonating a normal domain user, active directory objects are enumerated (e.g. BloodHound)
* T2: Owner rights of compromised user are found on domain controller object
* T3: Abuse owner rights by using resource based constrained delegation and user initiated domain join

# AV6: Lateral movement by abusing WriteAll permission of compromised user on domain administrator user object

* T1: Impersonating a normal domain user, active directory objects are enumerated (e.g. BloodHound)
* T2: WriteAll rights of compromised user are found on domain administrator object
* T3: Abuse rights by writing "Shadow Credentials" to the domain administrator object

# AV7: Lateral movement by kerberoasting domain administrator account

* T1: Impersonating a normal domain user, active directory users are enumerated for set service principal names
* T2: For found users service tickets are requested
* T3: Service Tickets are further attempted to be cracked
* T4: Credentials to a user with domain administrator rights are found

# AV8: Lateral movement to trusted domain by abusing trust relationship

* T1: Impersonating a domain administrator user, the nt-hash or aes kerberos keys of accoutn `krbtgt` are dumped
* T2: `krbtgt` credentials are further used to forge a golden ticket with added extra sid of high privileged group in ot.local
* T3: Since Kerberos tickets can not be used in this setup to authenticate using RDP (no RemoteCredentialGuard), persistence in the trusted domain is established by altering/creating users

# AV9: Credential access on the Fileserver in the Enterprise Network
The credentials for programming/accessing the Phoenix Contact AXC F 2152 were found in a photo on the file server within the enterprise network. The photo shows the PLC along with the initial credentials.

# Handover to OT

# AV10: Discovery and Credential access on the Windows Client in the Enterprise Network and lateral movement to Grafana (data historian)
Exploring the bookmarks in the Firefox app to check for access to internal web apps. A bookmark for the Grafana web app is discovered. Furthermore, login credentials for a regular user for Grafana are found in Firefox. They are stored there in plain text and accessible. These credentials are used to log in to the web app.

# AV11: Lateral movement to the Jumphost from the implant via RDP (if no user in the Enterprise domain has been granted Domain Admin rights or access to the OT domain)
Logging in to the Jumphost via RDP using the user account with access to the Jumphost from the Enterprise Domain. The user's credentials were found in plaintext within the Windows domain.

# AV12: Lateral Movement to the Jumphost from the implant in the the Enterprise Network via RDP(when a user with Domain Admin rights in the Enterprise domain has access to the OT domain)
Logging in to the Jumphost via RDP using the user account with Domain Admin rights in the OT domain.

# AV13: Privilege escalation on the Jumphost
If no Domain Admin rights are available, modifying or exploiting a scheduled task running with elevated privileges to execute custom code and thereby creating a shell with system privileges.

# AV14: Discovery on the Jumphost
* T1: Search for installed and running programms. Reveals that the KeePass password manager is installed and running.
* T2: The filesystem is searched for credentials and keys. A Private SSH key for access to the Data Historian is found.
* T3: Scanning is performed to detect access to internal web applications on the network, revealing access to the webapps of Grafana ans ScadaLTS.

# AV15: Credential access on the Jumphost 
The password manager KeePass, version 2.53.1, which is affected by the vulnerability CVE-2023-32784, is installed on the Jumphost and runs (but is locked) in the context of the user who has access to the Jumphost from the enterprise domain. The credentials for the admin user of the Grafana system and the credentials for the user of the Engineering Workstation are stored in KeePass. The vulnerability is exploited to gain unauthorized access to these credentials.
During the attack, a memory dump of KeePass is created. This dump is then transferred via an RDP connection to the implant to execute the exploit. Through the analysis of the memory dump, the master password of the KeePass container is extracted. The master password is used to gain access to the stored credentials.

# AV16: Lateral movement on the Grafana web application
Grafana admin credentials found in KeePass are used to access the web application.

# AV17: Impact in Grafana
Available operational information is exfiltrated directly from Grafana, for example, using screenshots (partially possible even without admin access).

# AV18: Credential Access on the Jumphost and Lateral Movement to the Data Historian (OS)
A private SSH key that provides access to the operating system of the Data Historian with a non-admin user is found and used. If not already logged in with the corresponding user, the file directory of the user with enterprise domain access to the Jumphost is searched. The SSH key is found there and subsequently used for access.

Since the SSH key is password-protected, the password must first be determined via a brute-force attack. For this purpose, the key is transferred from the Jumphost to the attacker’s device via the RDP connection. The brute-force attack is then performed on the attacker’s device, successfully decrypting the password. With the decrypted SSH key, access to the operating system of the Data Historian is achieved.

# AV19: Privilege Escalation on the Data Historian (OS)
A misconfiguration in the Sudoers file is sought, found and exploited. This allows vi to be executed by any user with sudo privileges. This misconfiguration makes it possible to launch a root shell from within vi by executing the command ":!bash".

# AV20: Impacts on the Data Historian (OS)
If root privileges are obtained, the files of the Data Historian database can be accessed, allowing operational information or the Data Historian's database to be extracted and exfiltrated via SCP and RDP.

# AV21: Lateral Movement to the Engineering Workstation
Credentials for the user (with local admin rights) of the Engineering Workstation are also stored in the password store on the Jumphost. The credentials are used to establish an RDP connection to the Engineering Workstation.

# AV22: Discovery on the Engineering Workstation
* T1: The bookmarks in the installed Edge browser are searched to check for access to internal web apps. Access to the ScadaLTS web app is found in the bookmarks.
* T2: Programs and documents on the engineering workstation are searched for information on access to additional systems. It is discovered that the PLCs in the environment are programmed using an installed IDE. Additionally, a document containing credentials for programming or accessing the ABB AC500 ECO v3 PLC is found.

# AV23: Credential Access and Lateral Movement from the Jumphost or Engineering Workstation to ScadaLTS
Default credentials are used for accessing ScadaLTS. These are identified and exploited for access.

# AV24: Impact on ScadaLTS
* T1: Derive information about the components in use.
* T2: Manipulate the automation process by altering alarm settings to suppress or trigger alarms.
* T3: Manipulation of control parameters (I/O values), resulting in the transmission of control commands to PLCs.

# AV25: Discovery, Credential Access and Lateral Movement from the Engineering Workstation to the SCADA Server (OS)
The ScadaLTS Version is found in the Login-Window. Exploitation of CVE-2023-33472, an RCE vulnerability in ScadaLTS (authentication within ScadaLTS is required). The exploitation is carried out via the "Event Handler" feature, where an command to the OS is sent and executed that creates a new user on the operating system and assigns this user to the sudo group. This is possible because the underlying ScadaLTS web service runs with root privileges. Subsequently, an SSH login to the operating system of the SCADA server is performed using the newly created credentials.

# AV26: Impact on SCADA Server (OS)
Manipulation of network traffic (PitM) from the PLCs and altering transmitted sensor data or status information. The tools used for this purpose are transferred via RDP to the Engineering Workstation and then transferred to the OS of the SCADA server via SCP, where they are installed.

# AV27: Credential Access on the Engineering Workstation
The credentials for programming/accessing the ABB AC500 ECO v3 PLC via the IDE were found in a document on the Engineering Workstation.
  
# AV28: Impact in the IDE on the Engineering Workstation and on the PLCs
The obtained PLC credentials are used to access the controllers via the IDE on the Engineering Workstation and to program them. First, the operating modes on the PLCs are changed, followed by modifications to the control logic and/or configuration parameters.

# AV29: Lateral Movement to the Webapp of the Phoenix Contact AXC F 2152 PLC and Impact on it
Previously identified credentials can be used to gain access to the web application, where the connection to ScadaLTS is disrupted by manipulating the firewall settings.

# AV30: Lateral Movement to the OS of the Phoenix Contact AXC F 2152 PLC
Previously identified credentials are used to access the OS via SSH.

# AV31: Priviledge Escalation on the OS of the Phoenix Contact AXC F 2152 PLC
To gain root privileges, the root password can be set directly when logged in as the admin user (as documented in the PLCnext Technology documentation).

# AV32: Impact on the Phoenix Contact AXC F 2152 PLC (OS)
Stop critical services.


