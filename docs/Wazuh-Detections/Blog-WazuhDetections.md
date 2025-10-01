# Introduction

I was really excited when we started setting up the early infrastructure and detection logic for the StealthCup. Somewhen around 2007 I started working part-time as a Windows network administrator one afternoon a week whilst studying computer science at the Leopold-Franzens university in Innsbruck and have been working as an admin (upgrading to full time eventually) until 2016 when I had enough of the constant ticket grinding and shifted my focus on penetration testing. The feeling of interacting with a target in a meterpreter shell captivated me and hasn't let me go since then.

So going back to actually setting up stuff to detect exploits was a task I greatly looked forward to and was very rewarding most of the time.

When thinking about which attack vectors to implement, we already had our thoughts but I wanted to make our decisions a bit more scientifically sound, that's why I conducted a small survey with pentesting firms on which vulnerabilities they encounter the most during their engagements. The goal of the StealthCup was not to fabricate CTF challenges but to present a corporate environment as found in the wild and monitor as good as possible using open source (or at least free) tooling and compare the detections to commercial products.

For the survey I curated a total of 14 attack vectors which relied on misconfigurations in Active Directory and could charm five firms to supply data and added my own statistics from my pentesting. I further tried to score each vulnerability using CVSS 4.0 to come up with some sort of index on how risky a misconfiguration may be measured on the severity and frequency of occurence in production environments:

| Attack Vector             | Frequency | CVSS4.0 | Risk Score | CVSS 4.0 String |
|---------------------------|-----------|---------|------------|-----------------|
| NTLM Relaying                   | 0.89     | 7.5      | 6.71     | CVSS:4.0/AV:A/AC:H/AT:P/PR:N/UI:P/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N/E:A                           |
| LDAP Relaying                   | 0.89     | 7.4      | 6.62     | CVSS:4.0/AV:A/AC:H/AT:P/PR:N/UI:P/VC:H/VI:H/VA:N/SC:N/SI:N/SA:N/E:A                           |
| WSUS Spoofing                   | 0.58     | 7.5      | 4.37     | CVSS:4.0/AV:A/AC:H/AT:P/PR:N/UI:P/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N/E:A                           |
| DomainJoin                      | 0.45     | 5.5      | 2.47     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:L/VI:L/VA:N/SC:H/SI:H/SA:H/E:A                           |
| Kerberoast - High               | 0.28     | 8.9      | 2.45     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H/E:A                           |
| ADCS - Template ESC1            | 0.27     | 8.9      | 2.42     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H/E:A                           |
| Delegations                     | 0.29     | 7.3      | 2.13     | CVSS:4.0/AV:A/AC:H/AT:P/PR:H/UI:A/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H/E:A                           |
| Weak AD ACL - Medium            | 0.27     | 5.5      | 1.47     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:L/VI:L/VA:N/SC:H/SI:H/SA:H/E:A                           |
| Pwd-Spraying - High             | 0.15     | 8.9      | 1.34     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H/E:A                           |
| ClearCreds - Low                | 0.56     | 2.1      | 1.19     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:L/VI:L/VA:N/SC:L/SI:L/SA:N/E:A                           |
| ClearCreds - Medium             | 0.20     | 5.5      | 1.11     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:L/VI:L/VA:N/SC:H/SI:H/SA:H/E:A                           |
| Pwd-Spraying - Low              | 0.47     | 2.1      | 0.98     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:L/VI:L/VA:N/SC:L/SI:L/SA:N/E:A                           |
| Credential Reuse - High         | 0.10     | 8.9      | 0.89     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H/E:A                           |
| Weak AD ACL - High              | 0.10     | 8.9      | 0.89     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H/E:A                           |
| Pwd-Spraying - Medium           | 0.15     | 5.5      | 0.84     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:L/VI:L/VA:N/SC:H/SI:H/SA:H/E:A                           |
| Credential Reuse - Low          | 0.35     | 2.1      | 0.74     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:L/VI:L/VA:N/SC:L/SI:L/SA:N/E:A                           |
| Weak AD ACL - Low               | 0.34     | 2.1      | 0.71     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:L/VI:L/VA:N/SC:L/SI:L/SA:N/E:A                           |
| ADCS - Relay ESC8               | 0.08     | 8.9      | 0.70     | CVSS:4.0/AV:A/AC:H/AT:P/PR:N/UI:P/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H/E:A                           |
| ClearCreds - High               | 0.08     | 8.9      | 0.68     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H/E:A                           |
| Credential Reuse - Medium       | 0.10     | 5.5      | 0.55     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:L/VI:L/VA:N/SC:H/SI:H/SA:H/E:A                           |
| Kerberoast - Low                | 0.25     | 2.1      | 0.53     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:L/VI:L/VA:N/SC:L/SI:L/SA:N/E:A                           |
| Domain Trust Abuse              | 0.05     | 8.8      | 0.46     | CVSS:4.0/AV:A/AC:L/AT:P/PR:H/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H/E:A                           |
| Kerberoast - Medium             | 0.08     | 5.5      | 0.42     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:L/VI:L/VA:N/SC:H/SI:H/SA:H/E:A                           |
| AS-REP-Roast - Low              | 0.05     | 2.1      | 0.11     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:L/VI:L/VA:N/SC:L/SI:L/SA:N/E:A                           |
| AS-REP-Roast - High             | 0.00     | 8.9      | 0.00     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H/E:A                           |
| AS-REP-Roast - Medium           | 0.00     | 5.5      | 0.00     | CVSS:4.0/AV:A/AC:L/AT:P/PR:L/UI:N/VC:L/VI:L/VA:N/SC:H/SI:H/SA:H/E:A                           |

And yes, I would happily discuss the CVSS scores and how you think it should have been scored!

I further tried to incorporate as much of these misconfigurations and detections for it as possible but of course had to drop some of them. But folliwing is the list of attack vectors we implemented in the environment and how I planned to have them detected.

Enjoy!

## Kerberoasting

In the world of corporate networks, a variety of services are hosted, including web applications, database servers, and directory services. For clients to access these services, they first need to go through an authentication process. This step is crucial to determine whether they are authorized and to identify the specific roles that grant them access to the requested resources.

While a straightforward solution might be to store user credentials and their access roles locally, this approach has its drawbacks. The most significant issue is that users would need to authenticate separately for each service they wish to access. This repetitive process can lead to poor password practices, as users may resort to choosing simpler passwords or saving them unencrypted on their devices or browsers for convenience.

Moreover, managing user roles separately across different services adds another layer of complexity. This administrative overhead can make it challenging to maintain fine-grained authorization, ultimately complicating the security landscape. In short, while local authentication may seem easy to implement, it can lead to a host of issues that compromise both security and user experience.

To tackle the challenges of authentication and authorization, one effective solution is to implement Kerberos authentication wherever possible. Kerberos tickets come with built-in group memberships defined in Active Directory, allowing for seamless authorization based on the roles and groups established within that directory.

Let’s take a closer look at how this works in practice. Imagine a client requesting a service on the local network. The authentication and authorization workflow would unfold in a structured manner, ensuring that the client’s access is both secure and efficient. Here’s a brief architectural overview of the process:

- Client requests to access service
- Service responds with "Negotiate" authentication request
- Client looks up the service principal name (SPN) of the service in Active Directory
- Client requests a service ticket for the found SPN at the key distribution center (KDC)
- Client attaches the service ticket to authentication request to the service
- Service accepts or rejects the service ticket and may further authorize the client to access resource based on the group memberships supplied in the service ticket

In 2015, security expert Tim Medin introduced the term "Kerberoast" during his talk "Attacking Kerberos." This term highlights a significant risk: service tickets are issued to any authenticated domain user, regardless of whether they are authorized to access the service. This means that an attacker could exploit this feature by requesting a service ticket, which is encrypted using the NT-Hash of the service account.

If an attacker successfully obtains this ticket, they may attempt to crack the encryption to reveal the clear-text credentials of the service account. A kerberoast attack follows the following steps:

- Use valid domain credentials
- LDAP query for (servicePrincipalName=*)
- Request service ticket for each found SPN and optionally downgrade encryption to RC4-HMAC (0x17)

If the attack succeeds and the clear-text credentials of the service account are retrieved, an attacker could move laterally through the domain, impersonating the compromised user and leveraging their associated authorizations, such as user rights. The potential impact of this breach varies significantly based on the rights of the compromised user. 


### Proposed Detection Strategy

To effectively collect successful TGS-REP tickets, event 4769 must be logged on the domain controller and sent to Wazuh for analysis. However, a closer examination of the detection rule reveals potential issues. In production environments where legacy encryption is still in use—such as with appliances that do not support AES encryption for Kerberos tickets—this design may lead to false positives. Additionally, if attackers choose not to downgrade to RC4 encryption, true positives could be missed, as AES-encrypted tickets can also be compromised using short word lists and reasonable rule sets.

To enhance detection accuracy and reduce errors, it’s essential to record, analyze, and correlate LDAP data. This approach will provide a more comprehensive view of the attack steps involved. However, logging LDAP queries requires enabling debugging flags, and the resulting event logs are not structured in a way that Wazuh can easily parse, as all parameters are logged as plain Data fields. To address this limitation, LDAP logs must be processed before being ingested into Wazuh. A practical solution is to create a utility script that runs periodically, parsing and reformatting LDAP logs for ingestion into Wazuh using a custom decoder. The steps to set up this task and decoder are outlined below.

Another way to access LDAP queries, particularly when LDAPS is not in use, is by capturing and analyzing network traffic with Suricata. The alerts generated can then be sent to Wazuh for further correlation and analysis. Given that Kerberoasting attacks often involve tools that enumerate and request tickets for all users with an SPN assigned, implementing a honey token user can serve as an effective detection strategy. This honey token user would exist solely to alert administrators to potential Kerberoasting attacks, as suggested in recent research. By creating this decoy, organizations can enhance their ability to detect and respond to unauthorized access attempts more effectively.

Steps to enable detection to be performed on a domain controller:
- Check if event 4769 gets logged, otherwise configure policy `Computer Configuration > Policies > Windows Settings > Security Settings > Advanced Audit Policy Configuration > Audit Policies > Account Logon > Audit Kerberos Service Ticket Operations: Configure the following audit events: Success`
- Turn on LDAP Logging
```
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics -Name "15 Field Engineering" -Value 5
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters -Name "Expensive Search Result Threshold" -PropertyType DWORD -Value 1
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters -Name "Inefficient Search Results Threshold" -PropertyType DWORD -Value 1
```
- Set Log size for `Directory Service` to 100MB+
- Setup Script according to LDAPQuerLogParserSetup.md
- Setup Scheduled Task to run LDAPQueryLogParser.ps1

The setup for the custom LDAPQueryLogParser to work is the following (content of `LDAPQueryLogParserSetup.md`):

Apart from the registry keys to enable dumping LDAP requests in event logs, the script `Write-LDAPQueryLog.ps1` which analyzes and transforms LDAP queries ingestable to Wazuh must run at least every minute on a domain controller. 

Per default the script writes data to `%PROGRAMDATA%\AIT` and the script should reside in `%PROGRAMFILES\AIT`. It saves a timestamp of its last execution in the registry key `HKLM:\SOFTWARE\AIT\LDAPQueryLogParser\LastRun`. This timestamp is used to determine which logs are new and have not yet been analyzed to ensure no duplicates are generated.

On the Wazuh server the custom decoder `LDAPQueryLogParser_decoder.xml` must be deployed in the custom decoder folder `/var/ossec/etc/decoders/`.

All files mentioned above are available on [StealthCup2025](https://github.com/ait-cs-IaaS/StealthCup2025).

The following ruleset alerts possible kerberoasting activity based on either of the cases:
- a service ticket for the honeytoken user was requested
- an RC4 encrypted service ticket was issued
- two or more RC4 encrypted service ticket were issued to the same IP Address in the timespan of 1 second
- an LDAP query for `servicePrincipalName=*` was issued towards the DC
- Composite alerts for the combinations of suspicious LDAP queries and RC4 encrypted tickets

Although the composite rules (100102 through 100105) should be the most precise in detection, I was not able to correlate the originating ip address from LDAP queries and issued RC4 tickets. Wazuh would stop triggering alerts if `<same_srcip />` was used, although ingestion seems to works correctly with `src_ip` being correctly parsed from LDAP query logs.


```xml
<group name="windows,activedirectoryattacks">
 <rule id="100100" level="4">
    <decoded_as>LDAPQueryLogParser</decoded_as>
    <description>LDAP Query from $(srcip): $(filter)</description>
    <group>ldap,</group>
  </rule>
</group>

<group name="kerberoast,windows,activedirectoryattacks">
  <rule id="100010" level="16">
    <if_sid>60103</if_sid>
    <field name="win.system.eventID">^4769$</field>
    <field name="win.eventdata.serviceName" type="pcre2">^(?i)(tracy|alfred|lillian|earl|nelson|melissa|willie|cliff|herman|lori|rosemarie)$</field>
    <description>Honey Token Service Account Ticket requested from $(win.eventdata.ipAddress) with $(win.eventdata.ticketEncryptionType) and $(win.eventdata.ticketOptions) for User $(win.eventdata.targetUserName)</description>
    <group>,honeytoken</group>
  </rule>
  
  <rule id="100006" level="13">
    <if_sid>60103</if_sid>
    <field name="win.system.eventID">^4769$</field>
    <field name="win.eventdata.TicketEncryptionType" type="pcre2">0x17</field>
    <description>Possible Keberoasting attack - Single RC4 encrypted TGS issued</description>
  </rule>
  
 <rule id="100007" level="16" frequency="2" timeframe="1">
    <if_matched_sid>100006</if_matched_sid>
    <different_field>serviceName</different_field>
    <description>Certain Kerberoasting attack - Multiple RC4 encrypted TGS issued in 1s</description>
  </rule>
  
  <rule id="100101" level="12">
     <if_sid>100100</if_sid>
     <field name="filter" type="pcre2">(?i)servicePrincipalName=\*</field>
     <description>Suspicious LDAP Query for SPNs found from $(srcip): $(filter)</description>
  </rule>
  
  <rule id="100102" level="16" timeframe="360">
    <if_sid>100101</if_sid>
    <if_matched_sid>100007</if_matched_sid>
    <description>Certain Kerberoasting attack - multiple RC4 ticket requests and suspicious LDAP Query detected</description>
  </rule>
  
  <rule id="100103" level="16" timeframe="360">
     <if_sid>100007</if_sid>
     <if_matched_sid>100101</if_matched_sid>
     <description>Certain Kerberoasting attack - RC4 ticket and suspicious LDAP Query detected</description>
  </rule>
  
     <rule id="100104" level="16" timeframe="360">
    <if_sid>100101</if_sid>
    <if_matched_sid>100006</if_matched_sid>
    <description>Certain Kerberoasting attack - $(win.eventdata.ipAddress): RC4 ticket request and suspicious LDAP Query detected</description>
  </rule>
  
  <rule id="100105" level="16" timeframe="360">
     <if_sid>100006</if_sid>
     <if_matched_sid>100101</if_matched_sid>
     <description>Certain Kerberoasting attack - RC4 ticket and suspicious LDAP Query detected</description>
  </rule>
</group>
```

## AS-REP Roasting

When Pre-Authentication is disabled on a user account, it opens the door for attackers to exploit this vulnerability. An attacker can forge an AS-REQ for the corresponding user and receive an AS-REP encrypted with the user's NT-hash. This AS-REP can then be cracked offline, as detailed in MITRE ATT&CK T1558.004.

The attack typically begins with the attacker enumerating user accounts that have Pre-Authentication disabled. Once these vulnerable accounts are identified, the attacker proceeds to send AS-REQ requests for the found users, setting the stage for potential credential compromise. This highlights the importance of ensuring that Pre-Authentication is enabled for all user accounts to mitigate such risks. 

- LDAP query for accounts with Pre-Authentication disabled
- AS-REQ for found accounts
- Offline crack AS-REP messages

If the attack is successful and the clear-text credentials of a user account are retrieved, the attacker can move laterally through the domain, impersonating the compromised user and leveraging their associated authorizations, such as user rights. The impact of this breach varies significantly based on the rights of the compromised user. 

### Proposed Detection Strategy

Steps to enable detection to be performed on a domain controller:
- Check if event 4768 gets logged, otherwise configure policy `Computer Configuration > Policies > Windows Settings > Security Settings > Advanced Audit Policy Configuration > Audit Policies > Account Logon > Audit Kerberos Authentication Service: Configure the following audit events: Success, Failure`

The following ruleset alerts possible kerberoasting activity based on either of the cases:
- an LDAP query for account having bit `4194304` set in `userAccountControl` (no Pre-Authentication) was issued towards the DC
- an RC4 encrypted ticket was issued without pre-authentication
- composite rules of suspicious LDAP queries and issued tickets without pre-authentication 

```xml
<group name="asreproast,windows,activedirectoryattacks">
  <rule id="100110" level="12">
     <if_sid>100100</if_sid>
     <field name="filter" type="pcre2">(?i)userAccountControl.4194304</field>
     <description>Suspicious LDAP Query for Users without Kerberos Pre-Authentication found from $(srcip): $(filter)</description>
  </rule>
  
  <rule id="100030" level="13">
    <if_sid>60103</if_sid>
    <field name="win.system.eventID">^4768$</field>
    <field name="win.eventdata.TicketEncryptionType" type="pcre2">0x17</field>
    <field name="win.eventdata.preAuthType">0</field>
    <description>Possible AS-REP Roasting attack - RC4 encrypted TGT without Pre-Autheintication issued for $(win.eventdata.targetUserName) from $(win.eventdata.ipAddress)</description>
  </rule>
  
  <rule id="100031" level="16" timeframe="360">
    <if_sid>100030</if_sid>
    <if_matched_sid>100110</if_matched_sid>
    <description>Certain AS-REP Roasting attack - RC4 ticket and suspicious LDAP Query detected</description>
  </rule>
  
  <rule id="100032" level="16" timeframe="360">
    <if_sid>100110</if_sid>
    <if_matched_sid>100030</if_matched_sid>
    <description>Certain AS-REP Roasting attack - RC4 ticket and suspicious LDAP Query detected</description>
  </rule>
</group>
```
## Credentials in Files
Passwords are intended to be kept secret, known only to the users who need them, adhering to the principle of least privilege. This principle helps to minimize the impact of compromised credentials by ensuring that access rights are limited to what is absolutely necessary.

In practice, the safest way to keep credentials secure would be to memorize them. However, following the recommendations from CISA for safe password creation and storage can make this a daunting task, especially for users managing high-value assets with complex passwords. As a result, many users resort to writing down their passwords, whether in password safes or even in plain text. If these credentials are stored in a location with strong access controls, the risk may be mitigated, as an attacker would need to compromise the user to access the stored information. However, if users choose to store their credentials in locations that do not adhere to the principle of least privilege—allowing other accounts at least read access—the credentials become vulnerable to compromise.

In addition to user credentials, service account credentials present another layer of security risk. These accounts are often managed by multiple users, necessitating ongoing evaluation of who has access to the credentials. Furthermore, service accounts may need to have their credentials saved in clear text within configuration files, particularly when the service cannot securely store its credentials in an encrypted format, as is often the case with web services. This situation underscores the importance of careful management and protection of both user and service account credentials.

Attackers often mimic normal file share access to search for credentials stored in clear text or reversible encryption across all hosts on the network. This process typically begins with querying the domain controller for all computer objects within the domain. The attacker then contacts each resource using SMB, enumerating the available shares, including hidden ones (for example, by using the command `net view <computername> /all`). Once all shares on the domain have been identified, the attacker can search for clear-text credentials, either manually or through automated methods.

This type of attack is recognized by MITRE ATT&CK as "Unsecured Credentials: Credentials in Files T1552.001."

If the attack is successful and the clear-text credentials of an account are retrieved, the attacker can move laterally through the domain, impersonating the compromised user and leveraging their associated authorizations, such as user rights. This highlights the critical need for organizations to secure their file shares and implement robust credential management practices to mitigate such risks.

### Proposed Detection Strategy

Detection is done using a honeyfile placed on a hidden share. This ensures to keep false positives low, since only "nosy" users may find and search the share, although attackers tools automatically find and search all hidden shares.

To enable logging, auditing for the spific share must also be enabled:

Computer Configuration > Policies > Windows Settings > Security Settings > Advanced Audit Policy Configuration > Audit Policies > Object Access > Audit File System: Configure the following audit events: Success
- Remove exclusion `and EventID != 4663 ` in ossec.conf
- Create honey token share
```
New-Item C:\Shares\sensitive -ItemType Directory
New-SmbShare -ReadAccess "Authenticated Users" -Name "Sensitive$" -Path C:\Shares\sensitive
Set-Content C:\Shares\sensitive\passwords.txt -Value "User1:P@ssw0rd"
```
- Set Auditing on created file
  - Properties > Security > Advanced > Auditing > Add 
  - Authenticated Users; Success; (Show advanced permissions) Listfolder/read data; Delete
  
```
$AuditRule = New-Object System.Security.AccessControl.FileSystemAuditRule('NT AUTHORITY\Authenticated Users','ReadData, Delete', 'none', 'none', 'Success')
$Acl = Get-Acl -Path C:\Shares\sensitive
$Acl.AddAuditRule($AuditRule)
Set-Acl -Path C:\Shares\sensitive -AclObject $Acl
```

## Domain Trust Misconfiguration
Domain trusts provide administrators with a valuable tool for allowing domain assets to access resources within another domain by establishing a trust relationship between the domain controllers of each domain. These trust relationships can be configured in specific directions or as bi-directional, enabling assets on both sides to be authorized to access resources on the other side. However, it’s important to understand that establishing a trust relationship does not automatically grant users access to resources in the trusted domain, as they are not members of any generic groups, such as "Domain Users." Users from a trusted domain must be explicitly granted access to resources in the other domain. With a trust relationship in place, security groups from the trusted domain become resolvable and can be utilized in access control lists (ACLs).

In terms of Kerberos secret exchange, domain trusts operate similarly to secret exchanges within the local domain, with the key difference being that secrets are exchanged between two Key Distribution Centers (KDCs), each associated with different krbtgt accounts. The most basic method for secret exchange involves replicating the hashes of the krbtgt accounts across the trust. If one domain is compromised, the other could also be at risk, as attackers could access the hash of the krbtgt account from the compromised domain. To mitigate this risk and limit the impact to the local domain, a separate trust key is implemented for secret exchanges between the two domains. This trust key is stored as an Active Directory object in each domain, named after the trusted domain.

A practical use case for implementing a trust between two domains could arise during the merger of two companies that wish to maintain their existing domains while allowing users to access resources in the other domain. Another scenario might involve migrating objects from one domain to another. To facilitate such migrations, administrators can utilize a feature called SIDHistory, which adds the group memberships from the original domain to the access token of the migrated user, ensuring that the user retains their permissions in the new domain.

To control the behavior of SIDHistory, trusts can be configured to either allow or deny group memberships based on the objects' SIDHistory. To prevent potential breaches in a trusted domain, it is advisable to deny SIDHistory across domain trusts by keeping the "SID Filtering" feature enabled, which is set to default on cross-forest trusts.

If SID Filtering is disabled across the trust to another domain, an attacker who fully compromises the local domain could forge a Golden Ticket that includes a high-value group from the other domain in its SIDHistory. This technique is associated with the MITRE ATT&CK framework as "Access Token Manipulation: SID-History Injection T1134.005." This highlights the importance of maintaining strict controls and configurations around domain trusts to safeguard against potential security threats.

### Proposed Detection Strategy
Research showed no specific event logs being written that are tied to cross forest trusts. Of course event IDs "4768: A Kerberos authentication ticket (TGT) was requested" and "4769: A Kerberos service ticket was requested" are still issued as with local logons. Analysis would have to resort to checking the "Account Domain" field of the event if the ticket request originated in a domain other than the local one. If request came from a trusted domain, it would further have to be checked if the TGT has SID-History attributes set and if theses are set, it would further have to be determined if those are to be considered malicious or normal. Although tickets issued to accounts from a trusted domain could be detected by Wazuh, it would not be possible to assess the SID-History contained in the tickets, since it is not documented in any event logs.
Trying to capture Kerberos tickets as they traverse the network using Suricata rules will also fail, since group memberships are stored in \verb|KERB_VALIDATION_INFO| part of the Privilege Attribute Certificate (PAC) which is encrypted.

Considering this difficulties, no suitable method for reliably detecting the abuse of Kerberos tickets across forest trusts can be proposed.

## Password Spraying

If an attacker successfully discovers clear-text credentials, their next move may be to test those credentials against other accounts within the domain. While the domain's password policy plays a significant role in this process, it's important to recognize that some accounts may be configured with never-expiring passwords. These passwords could have been set before a strict password policy was implemented or may have been established by an administrator who occasionally bypassed the policy.

To mitigate the risks associated with password spraying, organizations can set low account lockout thresholds and enforce periodic password changes. However, the most effective strategy to prevent successful password spraying is to ensure that unique passwords are issued for new accounts and that service accounts also utilize distinct passwords. Additionally, organizations should consider employing services that test user passwords against known leaked password lists, further enhancing their security posture. By implementing these practices, organizations can significantly reduce the likelihood of credential compromise and unauthorized access.

To minimize the risk of account lockouts, this brute-forcing attack employs a strategy that tests a limited number of passwords against many users, rather than attempting numerous passwords on a single account. This approach allows the attacker to gradually increase the count of failed password attempts without triggering immediate lockouts. By aligning the attack with the domain's password policy—specifically respecting account lockout thresholds and timeouts—it's possible for the attacker to avoid lockouts altogether, provided that users do not enter incorrect passwords during the password spraying attack.

This technique is documented in the MITRE ATT&CK framework as "Brute Force: Password Spraying T1110.003." By understanding this method, organizations can better prepare their defenses against such attacks and implement measures to protect user accounts effectively.

### Proposed Detection Strategy

With the steps set earlier:
- Check if event 4768 gets logged, otherwise configure policy `Computer Configuration > Policies > Windows Settings > Security Settings > Advanced Audit Policy Configuration > Audit Policies > Account Logon > Audit Kerberos Authentication Service: Configure the following audit events: Success, Failure`

Since failures in Kerberos logons are now also recorded, this enriches already existing Wazuh rule 60204 in 0580-win-security_rules.xml.

## Adding new Computer Objects to the Domain and Writing AD Objects

By default, users in Active Directory are permitted to add up to ten computer accounts to the domain, regardless of their group memberships. Additionally, the user who adds a computer object is designated as the owner of that object, granting them full control over it. This capability poses a significant risk if an attacker gains access to domain credentials, as they could add computer objects to the domain using their own credentials. Furthermore, they could exploit the attribute `msDS-AllowedToActOnBehalfOfOtherIdentity` to carry out attacks based on Resource-Based Constrained Delegation.

While the act of adding new computers to Active Directory may not seem threatening in isolation, it can be leveraged in an exploit chain to escalate local privileges or compromise computer objects where the attacker has obtained `GenericWrite` access.

Users can join a domain either through the graphical user interface during the initial setup by entering valid domain credentials or by using various tools. When utilizing these tools, the password for the computer object can be specified manually, rather than being assigned a random complex password of 120 characters, as is the default setting.

This technique is mapped to the MITRE ATT&CK framework as "Create Account T1136".

### Proposed Detection Strategy

Monitor event ID 5136 on the domain controller. This event indicates that a new computer account has been created in Active Directory. By correlating this event against a whitelist of user accounts that are authorized to add new computers to the domain, unauthorized attempts to create computer accounts can be detected.

For event 4741 to be logged two things must be configured:

- an auditing policy
- SACLs for the audited objects

First is enabled by setting the following in a group policy targeting domain controllers:
`Computer Configuration > Policies > Windows Settings > Security Settings > Advanced Audit Policy Configuration > Audit Policies > DS Access > Audit Directory Service Changes: Configure the following audit events: Success`

This enables auditing of event 5136 in general and as with monitoring of folder access, the audited object must also be enabled. This can be either done interactively:
  - dsa.msc
  - right-click domain root
  - Properties > Security > Advanced > Auditing > Add
  - Principal: Authenticated Users, Type: Success, Applies to: This object and all descendant objects
  - scroll down, click `clear all`
  - Tick `Write All Properties` in Permissions and Properties

Or by using the following script, replacing `DC=DEMOCORP,DC=LOCAL` with the name of your lab domain:

```powershell
Import-Module ActiveDirectory
$auditRule = New-Object System.DirectoryServices.ActiveDirectoryAuditRule([System.Security.Principal.SecurityIdentifier]'S-1-5-11', [System.DirectoryServices.ActiveDirectoryRights]::WriteProperty, [System.Security.AccessControl.AuditFlags]::Success, [System.DirectoryServices.ActiveDirectorySecurityInheritance]::All)
$acl = Get-Acl -Path "AD:DC=DEMOCORP,DC=LOCAL" -Audit
$acl.AddAuditRule($auditRule)
Set-Acl -Path "AD:DC=DEMOCORP,DC=LOCAL" -AclObject $acl
```

If events are correctly logged, the following ruleset can detect changes to specified Active Directory object attributes:

```xml
<group name="ADObjects,RBCD,windows,activedirectoryattacks">
  <rule id="100050" level="3">
    <if_sid>60103</if_sid>
    <field name="win.system.eventID">^5136$</field>
    <description>User $(win.eventdata.subjectUserName) changed property $(win.eventdata.attributeLDAPDisplayName) on $(win.eventdata.objectClass) $(win.eventdata.objectDN) to $(win.eventdata.attributeValue).</description>
  </rule>
  
  <rule id="100051" level="3">
    <if_sid>60229</if_sid>
    <field name="win.eventdata.objectClass" type="pcre2">^(?i)computer$</field>
    <description>User $(win.eventdata.subjectUserName) changed property $(win.eventdata.attributeLDAPDisplayName) on computer $(win.eventdata.objectDN) to $(win.eventdata.attributeValue).</description>
  </rule>
  
  <rule id="100052" level="12">
    <if_sid>100051</if_sid>
    <field name="win.eventdata.attributeLDAPDisplayName" type="pcre2">^(?i)sAMAccountName$</field>
    <list field="win.eventdata.subjectUserName" lookup="not_match_key">etc/lists/DomainJoiners</list>
    <list field="win.eventdata.subjectUserName" lookup="not_match_key">etc/lists/Admins</list>
    <description>User initiated Domain Join: User $(win.eventdata.subjectUserName) added computer $(win.eventdata.attributeValue) to the domain, although not in allowed domain joiners group.</description>
  </rule>
  
  <rule id="100053" level="3">
    <if_sid>100051</if_sid>
    <field name="win.eventdata.attributeLDAPDisplayName" type="pcre2">^(?i)msDS-AllowedToActOnBehalfOfOtherIdentity$</field>
    <description>RBCD Configuration: User $(win.eventdata.subjectUserName) configured RBCD on computer $(win.eventdata.objectDN).</description>
  </rule>
  
  <rule id="100054" level="16">
    <if_sid>100053</if_sid>
    <list field="win.eventdata.subjectUserName" lookup="not_match_key">etc/lists/DomainJoiners</list>
    <list field="win.eventdata.subjectUserName" lookup="not_match_key">etc/lists/Admins</list>
    <description>RBCD Abuse: User $(win.eventdata.subjectUserName) configured RBCD on computer $(win.eventdata.objectDN) although not member of privileged groups.</description>
  </rule>
</group>
```

For this to work two CDBs also must be deployed on the Wazuh server, containing the usernames one by line of who is allowed to add computers to the domain and domain administrators in general:

- /var/ossec/etc/lists/DomainJoiners
- /var/ossec/etc/lists/Admins

## NTLM Relaying

NTLM relaying attacks exploit the NTLM (NT LAN Manager) authentication protocol, which is still used in many Windows environments and involve three main components: the attacker, the victim, and the target server. Here’s how the attack unfolds:

- The attacker positions themselves between a client and a server (often through techniques like ARP spoofing or other poisoning attacks). When the client attempts to authenticate to the server, the attacker captures the NTLM authentication messages.
- NTLM uses a challenge-response mechanism for authentication. When a client wants to authenticate, the server sends a random challenge (a nonce) to the client.
- The client responds to the challenge by hashing it with the user's password hash. This response is then sent back to the server.
- The attacker initiates an NTLM authentication flow with the relay target (e.g. the server) and forwards the sent challenge to the client which initiated to authenticate with the attacker.
- The client creates a response by hashing the challenge with the password hash. This response is sent back to the atacker.
- The attacker can take the captured response and relay it to the server that supplied the challenge.

### Proposed Detection Strategy

Since in theory the thing that separates valid from malicious NTLM authentication flows is the forwarding of the challenge from the targeted server to the client, detection may be achieved like:

- extract NTLM challenge from packets
- compare challenges
- if duplicates are found, alert
- further enhance detection by analyzing relayed victim host and target host

While this may seem like a sound plan itself, I could not implement it using Suricata and Wazuh. I was able to identify and tag packets which include NTLM authentication using suricata but could not see any possiblities to extract the challenge from the packets to have it compared by Wazuh.

So what I ended up with was the following detection logic:

- tag packets that include NTLM authentication messages
- check if multiple (2+) NTLM authentication messages which occur in a 1s timeframe are issued to different hosts

Well what should I say, the expected performance of this rule was low due to it being as precise as a squadron of Stormtroopers. But it even managed to perform below expactations during the StealthCup and caused severe headaches and manual live point corrections during the event. I did not calculate the false positive rate yet but would say it was at something like 30% but it at least seemed to have catched all actual relaying operations too when comparing detections to the write-ups posted by the teams.

Here's what I ended up with and do encourage you to use with caution:

```
# NTLM relay ESC8
# detect NTLM authentication challenge from CA
alert http any any -> any any (msg:"NTLM authentication challenge in HTTP"; flow:established,to_client; http.header.raw; content:"WWW-Authenticate|3A 20|NTLM|0D 0A|"; metadata: ntlmssp challenge; sid:20; rev:3; priority:1;)

# NTLMSSP + NTLMSSP_CHALLENGE
alert smb any 445 -> any any (msg:"NTLMSSP_CHALLENGE"; content:"|4E 54 4C 4D 53 53 50 00 02 00 00 00|"; metadata: ntlmssp challenge; sid:21; rev:2; priority:1;)
alert tcp any 445 -> any any (msg:"NTLMSSP_CHALLENGE"; content:"|4E 54 4C 4D 53 53 50 00 02 00 00 00|"; metadata: ntlmssp challenge; sid:211; rev:2; priority:1;)


# NTLM relay ESC8
# detect NTLM authorization to CA
alert http any any -> any any (msg:"NTLM authorization response in HTTP"; flow:established,to_server; http.header.raw; content:"Authorization|3A 20|NTLM|0D 0A|"; metadata: ntlmssp response; sid:22; rev:2; priority:1;)
alert tcp any any -> any any (msg:"NTLM authorization response in HTTP"; content:"Authorization|3A 20|NTLM|0D 0A|"; metadata: ntlmssp response; sid:221; rev:2; priority:1;)
```

The main function of this (Suricata) rules is tagging the packets with metadata `ntlmssp challenge` and `ntlmssp response`. Since the challenge could not be extracted any further, Wazuh only used `ntlmssp challenge`:

```xml
<group name="relay,windows,activedirectoryattacks,suricata">
  <rule id="100070" level="3">
    <if_sid>86601</if_sid>
    <field name="alert.metadata.ntlmssp">challenge</field>
    <description>NTLM Challenge from $(src_ip) to $(dest_ip)</description>
  </rule>

  <rule id="100071" level="16" frequency="2" timeframe="1">
    <if_matched_sid>100070</if_matched_sid>
    <different_field>src_ip</different_field>
    <description>Certain NTLM relaying from $(src_ip) to $(dest_ip)</description>
  </rule>
</group>
```

The only theoretical possiblity to actually extract and compare the challenge using this approach would have been to make separate Suricata rules for every byte of the challenge and every possible byte value to map it to metadata. This would end up with 2048 Suricata rules whose generation could be completely automated and could theoretically supply metadata like:

```
challenge_byte1: 11
challenge_byte2: 22
challenge_byte3: 33
challenge_byte4: 44
...
```

Which could then be compared by Wazuh using the `<same_field>` tag. But I have not experimented with this (yet).

Maybe this could also have been solved by using LUA scripts in Suricata?

## Process Memory Access

As the reader might have guessed, detection logic mainly focused on attacks towards Active Directory, which was due to it being the core interest my masters thesis covers. But since no detection logic was present by default in Wazuh which focuses on endpoint attacks, I at least implemented detections for process memory access since it was part of the attack chain.

Being able to access the memory of other processes, may reveal secrets stored there as with the infamous dump of `lsass.exe` done by `mimikatz` to reveal NT-hashes, Kerberos tickets and other sensitive information. The attack chain also featured a locally running instance of `KeePass` in a vulnerable version which had to be dumped to extract the password database password. Of course other processes may also be of interest concerning memory access but the focus was on detectino along the attack chain.

### Proposed Detection Strategy

Sysmon is a great option to capture process access and integrates into Wazuh really well since Wazuh already has rules which handle Sysmon events collected in groups. So the main part was rolling out Sysmon to the clients.

I took the configurations from (https://github.com/SwiftOnSecurity/sysmon-config) and configured process access to include `KeePass.exe`. The supplied `sysmonconfig.xml` is what we ended up pushing to the clients in the lab.

The events were processed by Wazuh using the following ruleset:

```xml
<group name="windows,activedirectoryattacks,ProcessAccess,">
  <rule id="100210" level="15">
    <if_group>sysmon_event_10</if_group>
    <match>KeePass.exe</match>
    <description>KeePass.exe accessed</description>
  </rule>
  <rule id="100211" level="15">
    <if_group>sysmon_event_10</if_group>
    <match>lsass.exe</match>
    <description>lsass.exe accessed</description>
  </rule>
  <rule id="100212" level="1">
    <if_sid>100210, 100211</if_sid>
    <field name="win.eventdata.sourceImage" type="pcre2">^(?i)(C:\\\\Windows\\\\system32\\\\csrss\.exe|C:\\\\Windows\\\\system32\\\\wininit\.exe|C:\\\\Windows\\\\Sysmon64\.exe|C:\\\\Windows\\\\system32\\\\svchost\.exe|C:\\\\Windows\\\\Explorer\.EXE|C:\\\\Windows\\\\system32\\\\lsass\.exe|C:\\\\Users\\\\[0-9a-zA-Z\.-]{1,}\\\\Desktop\\\\keepass\\\\KeePassStarter\.exe|C:\\\\Program Files \(x86\)\\\\ossec-agent\\\\wazuh-agent\.exe|C:\\\\Program Files\\\\ossec-agent\\\\wazuh-agent\.exe)$</field>
    <description>Filtered false positive</description>
  </rule>
</group>
```

## Wazuh agent tampering

Unfortunately Wazuh does not offer protection against just being turned off altogether as common AV and EDR products do. An attacker with local administrator privileges may just stop and disable the wazuh service. As simple as that, no more events from that endpoint.

### Proposed Detection Strategy

Wazuh offers rules which handle disabled agents or agents whose heartbeat gone missing:

```xml
<group name="wazuh agent,">
  <rule id="100230" level="11">
    <if_sid>504, 506</if_sid>
    <description>Wazuh agent connection lost.</description>
    <mitre>
      <id>T1562.001</id>
    </mitre>
    <group>pci_dss_10.6.1,pci_dss_10.2.6,gpg13_10.1,gdpr_IV_35.7.d,hipaa_164.312.b,nist_800_53_AU.6,nist_800_53_AU.14,nist_800_53_AU.5,tsc_CC7.2,tsc_CC7.3,tsc_CC6.8,</group>
  </rule>
</group>
```

Although these detections would have worked in the lab, surprisingly no attendants tried to impair Wazuh during StealthCup.

## Malicious Network Traffic

Monitoring network traffic with Suricata is essential for detecting emerging threats due to its powerful capabilities in deep packet inspection and real-time analysis. By examining the contents of network packets beyond just headers, Suricata can identify malicious payloads and suspicious patterns indicative of attacks. Its dual approach of signature-based and anomaly-based detection allows it to recognize both known threats and new, previously unseen attacks. Supporting multiple protocols such as HTTP, DNS, and TLS, Suricata effectively monitors diverse traffic types while integrating with external threat intelligence feeds to stay updated on the latest vulnerabilities. With detailed logging and alerting features, it enables security teams to respond swiftly to potential threats, and its scalability ensures high performance in large networks. As an open-source tool, Suricata benefits from a vibrant community that continuously enhances its capabilities, making it a vital asset for organizations aiming to bolster their cybersecurity defenses against evolving threats.

### Proposed Detection Strategy

The first thing you possibly read on how to configure Suricata concerning rulesets is the `Emerging Threats` rules. This ruleset is continously developed by the community and will be ingested into Suricata with `sudo suricata-update` as mentioned in the [Suricata Quick Start Guide](https://docs.suricata.io/en/latest/quickstart.html).

So detecting malicious activity on the network should be easy as:

- Setup Suricata
- `suricata-update`
- add custom rules for relaying
- add additional rules found on blogs

And it was that simple. 

With the first millisecond the Suricata service restarted to apply all rules it happily started generating alerts. 

Many alerts.

With a newly deployed infrastructure in which no attack whatsoever took place, Wazuh started with about 20k event generated by Suricata.

It was clear that this needed some special attention.

A lot of alerts seemed to have come from that fact that the infrastructure was running in AWS and portmirroring with vxlan encapsulation was used which generated some weird behaviour of ET rules alerted as `Generic Protocol Command Decode`. Another thing that caught my attention was that rules seemed to use differing properties for severity. To take a step back why this is important: Wazuh has a single rule which handles all alerts generated by Suricata, no matter it's contents. Rule 86601 looks as the following:

```xml
<rule id="86601" level="3">
    <if_sid>86600</if_sid>
    <field name="event_type">^alert$</field>
    <description>Suricata: Alert - $(alert.signature)</description>
    <options>no_full_log</options>
</rule>
```

So to map the severities of the generated alerts, I initially resorted to the property `alert.severity`, thinking I had "managed" Suricata alerts.

After another flood of alerts I had the feeling that severities may be mapped a bit weird in some cases. Why I had another look at the alerts that stood out. This revealed another property of interest called `alert.metadata.signature_severity` which seemed to have values from `Informational, Minor, Major, Critical`. 

After tinkering with how to make Wazuh rules properly map severity to alerts which have both `alert.severity` AND `alert.metadata.signature_severity` set, I came up with the following rules to handle Suricata and filter out mentioned Protocol noise and other possibly experimental or IMHO scored too severe alerts:

```xml
<group name="suricata, ids">
  <rule id="100080" level="0">
    <if_sid>86601</if_sid>
    <field name="alert.category">Generic Protocol Command Decode</field>
    <description>Filtered Suricata Alert from Generic Protocol Command Decode: $(alert.signature)</description>
  </rule>
  <rule id="100082" level="0">
    <if_sid>86601</if_sid>
    <field name="dest_ip" type="pcre2">^169\.254\.169\.254$</field>
    <description>Filtered Suricata Alert: $(alert.signature)</description>
  </rule>
  <rule id="100084" level="16">
    <if_sid>86601</if_sid>
    <field name="alert.severity">4</field>
    <description>Critical Suricata Alert: $(alert.signature)</description>
  </rule>
  <rule id="100085" level="13">
    <if_sid>86601</if_sid>
    <field name="alert.severity">3</field>
    <description>High Suricata Alert: $(alert.signature)</description>
  </rule>
  <rule id="100086" level="9">
    <if_sid>86601</if_sid>
    <field name="alert.severity">2</field>
    <description>Medium Suricata Alert: $(alert.signature)</description>
  </rule>
  <rule id="100087" level="1">
    <if_sid>86601</if_sid>
    <field name="alert.severity">1</field>
    <description>Low Suricata Alert: $(alert.signature)</description>
  </rule>
  <rule id="100088" level="13">
    <if_sid>86601</if_sid>
    <field name="alert.message" type="pcre2">DRSUAPI</field>
    <description>Possible DCSync</description>
  </rule>
  <rule id="100083" level="2">
    <if_sid>100086</if_sid>
    <field name="alert.signature">POSSBL PORT SCAN</field>
    <description>Filtered Suricata Alert: $(alert.signature)</description>
    <options>no_log</options>
  </rule>
  <rule id="100095" level="2">
    <if_sid>100086</if_sid>
    <field name="alert.signature_id" type="pcre2">nothing</field>
    <description>Filtered Suricata Alert: $(alert.signature)</description>
  </rule>
  <rule id="100089" level="9" frequency="50" timeframe="1">
    <if_matched_sid>100083</if_matched_sid>
    <description>Possible Port Scan</description>
  </rule>
  <rule id="100081" level="3">
    <if_sid>100084, 100085, 100086, 100087</if_sid>
    <field name="alert.metadata.signature_severity">Informational</field>
    <description>Informational Suricata Alert: $(alert.signature)</description>
  </rule>
  <rule id="100096" level="7">
    <if_sid>100084, 100085, 100086, 100087</if_sid>
    <field name="alert.metadata.signature_severity">Minor</field>
    <description>Medium Suricata Alert: $(alert.signature)</description>
  </rule>
  <rule id="100097" level="13">
    <if_sid>100084, 100085, 100086, 100087</if_sid>
    <field name="alert.metadata.signature_severity">Major</field>
    <description>High Suricata Alert: $(alert.signature)</description>
  </rule>
  <rule id="100098" level="16">
    <if_sid>100084, 100085, 100086, 100087</if_sid>
    <field name="alert.metadata.signature_severity">Critical</field>
    <description>Critical Suricata Alert: $(alert.signature)</description>
  </rule>
  <rule id="100093" level="3">
    <if_sid>100084, 100085, 100086, 100087</if_sid>
    <field name="alert.signature">TGI HUNT</field>
    <description>TGI HUNT Suricata Alert: $(alert.signature)</description>
  </rule>
  <rule id="100094" level="3">
    <if_sid>100084, 100085, 100086, 100087</if_sid>
    <field name="alert.category">Not Suspicious Traffic</field>
    <description>Not Suspicious Traffic: $(alert.signature)</description>
  </rule>
</group>
```

## Other filtering rules

Added to the rules mentioned, I also included some more to filter unwanted behaviour. Please keep in mind, that we tried to keep alerts as precise as possible to only trigger true positives, since the triggered alerts directly added to the detection scores of competing teams.

In a produciton environment with a SOC in charge, most of these alerts may be wanted to be visible to aid in investigations:

```xml
<group name="filtering">
  <rule id="999993" level="0">
    <if_group>syslog, dpkg, config_changed</if_group>
    <description>Filtered dpkg alerts</description>
  </rule>
  <rule id="999994" level="0">
    <if_sid>60112</if_sid>
    <field name="win.eventdata.subjectLogonId">0x3e7</field>
    <description>Filtered Policy Modification by local SYSTEM</description>
  </rule>
  <rule id="999995" level="0">
    <if_group>sysmon_eid1_detections</if_group>
    <description>Filtered Sysmon Wazuh default rules</description>
  </rule>
  <rule id="999996" level="0">
    <if_group>sysmon_eid10_detections</if_group>
    <description>Filtered Sysmon Wazuh default rules</description>
  </rule>
  <rule id="999997" level="0">
    <if_group>sysmon_eid11_detections</if_group>
    <description>Filtered Sysmon Wazuh default rules</description>
  </rule>
  <rule id="999998" level="3">
    <if_sid>18154</if_sid>
    <description>Down-grade Windows Application Errors</description>
  </rule>
  <rule id="999999" level="0">
  <if_group>vulnerability-detector</if_group>
  <description>Filter Vulnerability Detection Alerts</description>
  </rule>
</group>
```