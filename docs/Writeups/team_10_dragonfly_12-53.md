[TOC]


# Summary
<media-tag src="https://files.cryptpad.fr/blob/b0/b03aa22f68ed52290ab7b9fa6ca87bb8855c97c2d327f071" data-crypto-key="cryptpad:EBGlRMM9TW3Gq3nEVJfiXiSs9EDDPH6eizDY+XMUQWI="></media-tag>
<media-tag src="https://files.cryptpad.fr/blob/fa/fa87f7b47f4f1d8fddb7f993aa1c4eb3343d99b00aa65578" data-crypto-key="cryptpad:yk5fuSXG0tuOTszLlceFgSc67gS1iqLRj0zawVf6M14="></media-tag>
----------------------------- IT -----------------------------
## 10.0.10.11 (DC1.PLUMETECH.LOCAL) (Windows Domain controller)
```
22/tcp    open     ssh
53/tcp    open     domain
80/tcp    open     http
135/tcp   open     msrpc
139/tcp   open     netbios-ssn
445/tcp   open     microsoft-ds
3389/tcp  open     ms-wbt-server
5985/tcp  open     wsman
```
- rdp login with alice does not work

## 10.0.10.12 (FS1.PLUMETECH.LOCAL) (Windows)
```
22/tcp    open     ssh
80/tcp    open     http
135/tcp   open     msrpc
139/tcp   open     netbios-ssn
445/tcp   open     microsoft-ds
3389/tcp  open     ms-wbt-server
5985/tcp  open     wsman
```
- rdp login with alice does not work

## 10.0.10.17 (Router)
- No open ports

## 10.0.10.29 (CLI1.PLUMETECH.LOCAL) (Windows)
```
22/tcp    open     ssh
135/tcp   open     msrpc
139/tcp   open     netbios-ssn
445/tcp   open     microsoft-ds
3389/tcp  open     ms-wbt-server
5985/tcp  open     wsman
MAC Address: 02:6D:84:0D:70:79
```
- rdp login with alice **does** work


----------------------------- DMZ -----------------------------

## 10.0.10.43 (OTDC1.PLUMETECH-OT.LOCAL) (Windows)
- No open ports

## 10.0.10.44 (JUMP.PLUMETECH-OT.LOCAL) (Windows)
```
3389/tcp  open     ms-wbt-server
```
- rdp login with alice does not work

## 10.0.10.45 (HIST.PLUMETECH-OT.LOCAL) (Ubuntu)
- No open ports

----------------------------- SCADA -----------------------------

## 10.0.10.59 (ENG1.PLUMETECH-OT.LOCAL) (Windows)

## 10.0.10.60 (SCADA.PLUMETECH-OT.LOCAL) (Ubuntu)
- No open ports

----------------------------- PLC -----------------------------

## 10.0.10.74 (PLC1) (Ubuntu Server)



# Users
## Creds
- `alice` : `Demo@123`
- `Nina` : ????


- Alice Smith  :  alice@plumetech.local  :  CEO
- Jack Morris  :  jack@plumetech.local  :  CTO
- Martin Scott  :  martin@plumetech.local  :  Head of Security Operations
- Sabrina Rodriguez  :  sabrina@plumetech.local  :  Director of Operations
- nina?

<media-tag src="https://files.cryptpad.fr/blob/20/20e01755ab062762f3fdd041d2a4c7044b73eb8f196401c6" data-crypto-key="cryptpad:Xx6iY5latrO2QX/dIMPdNxmn2BJ4DFiE/hS0XxIr/EY="></media-tag>

# Raw data

```
$ ip a
[...]
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 02:c5:25:80:1d:6d brd ff:ff:ff:ff:ff:ff
    inet 10.0.10.30/28 brd 10.0.10.31 scope global dynamic eth0
       valid_lft 2334sec preferred_lft 2334sec
    inet6 fe80::c5:25ff:fe80:1d6d/64 scope link proto kernel_ll
       valid_lft forever preferred_lft forever
```

```shell
$ ip n
10.0.10.29 dev eth0 lladdr 02:6d:84:0d:70:79 DELAY
10.0.10.17 dev eth0 lladdr 02:76:c2:0b:d7:45 REACHABLE
```

```
$ ip r
default via 10.0.10.17 dev eth0
10.0.10.16/28 dev eth0 proto kernel scope link src 10.0.10.30
```

```
$ nbtscan -v 10.0.10.17-29
Doing NBT name scan for addresses from 10.0.10.17-29


NetBIOS Name Table for Host 10.0.10.29:

Incomplete packet, 155 bytes long.
Name             Service          Type
----------------------------------------
CLI1             <00>             UNIQUE
PLUMETECH        <00>              GROUP
CLI1             <20>             UNIQUE

Adapter address: 02:6d:84:0d:70:79
----------------------------------------
```

```
└─$ nmap -sV -T2 --max-retries 1 --scan-delay 1s -p 135 -Pn 10.0.10.29
Starting Nmap 7.95 ( https://nmap.org ) at 2025-03-28 09:35 UTC
Nmap scan report for 10.0.10.29
Host is up (0.00015s latency).

PORT    STATE SERVICE VERSION
135/tcp open  msrpc   Microsoft Windows RPC
MAC Address: 02:6D:84:0D:70:79 (Unknown)
Service Info: OS: Windows; CPE: cpe:/o:microsoft:windows

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 9.97 seconds
                                                                                                                                                           
┌──(kali㉿kali)-[~]
└─$ nmap -sV -T2 --max-retries 1 --scan-delay 1s -p 139,445,3389,5985 -Pn 10.0.10.29
Starting Nmap 7.95 ( https://nmap.org ) at 2025-03-28 09:37 UTC
Nmap scan report for 10.0.10.29
Host is up (0.00033s latency).

PORT     STATE SERVICE       VERSION
139/tcp  open  netbios-ssn   Microsoft Windows netbios-ssn
445/tcp  open  microsoft-ds?
3389/tcp open  ms-wbt-server Microsoft Terminal Services
5985/tcp open  http          Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
MAC Address: 02:6D:84:0D:70:79 (Unknown)
Service Info: OS: Windows; CPE: cpe:/o:microsoft:windows

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 29.73 seconds


```

```
dig FS1.PLUMETECH.LOCAL @10.0.10.11

; <<>> DiG 9.20.4-4-Debian <<>> FS1.PLUMETECH.LOCAL @10.0.10.11
;; global options: +cmd
;; Got answer:
;; WARNING: .local is reserved for Multicast DNS
;; You are currently testing what happens when an mDNS query is leaked to DNS
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 21484
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4000
;; QUESTION SECTION:
;FS1.PLUMETECH.LOCAL.           IN      A

;; ANSWER SECTION:
FS1.PLUMETECH.LOCAL.    1200    IN      A       10.0.10.12

;; Query time: 4 msec
;; SERVER: 10.0.10.11#53(10.0.10.11) (UDP)
;; WHEN: Fri Mar 28 10:12:40 UTC 2025
;; MSG SIZE  rcvd: 64

```

## Nmap results
Command used:
```
nmap -sS -T2 --max-retries 1 --scan-delay 1s -p 21,22,23,25,53,80,110,135,139,443,445,1433,1521,3306,3389,5900,5985,5986,47808 -Pn -n 10.0.10.17-30
```
Command for versions:
```
nmap -sV -T2 --max-retries 1 --scan-delay 1s -p 135 -Pn 10.0.10.29
nmap -sV -T2 --max-retries 1 --scan-delay 1s -p 139,445,3389,5985 -Pn 10.0.10.29
```

Results
```
nmap -sV -T2 --max-retries 1 --scan-delay 1s -p 135 -Pn 10.0.10.29
nmap -sV -T2 --max-retries 1 --scan-delay 1s -p 139,445,3389,5985 -Pn 10.0.10.29
PORT    STATE SERVICE VERSION
135/tcp open  msrpc   Microsoft Windows RPC
MAC Address: 02:6D:84:0D:70:79 (Unknown)
Service Info: OS: Windows; CPE: cpe:/o:microsoft:windows
139/tcp  open  netbios-ssn   Microsoft Windows netbios-ssn
445/tcp  open  microsoft-ds?
3389/tcp open  ms-wbt-server Microsoft Terminal Services
5985/tcp open  http          Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
MAC Address: 02:6D:84:0D:70:79 (Unknown)
Service Info: OS: Windows; CPE: cpe:/o:microsoft:windows
```

```
Nmap scan report for 10.0.10.11
Host is up (0.0026s latency).

PORT      STATE    SERVICE
22/tcp    open     ssh
53/tcp    open     domain
80/tcp    open     http
135/tcp   open     msrpc
139/tcp   open     netbios-ssn
445/tcp   open     microsoft-ds
3389/tcp  open     ms-wbt-server
5985/tcp  open     wsman
```
```
Nmap scan report for 10.0.10.29
Host is up (0.00049s latency).

PORT      STATE    SERVICE
22/tcp    open     ssh
135/tcp   open     msrpc
139/tcp   open     netbios-ssn
445/tcp   open     microsoft-ds
3389/tcp  open     ms-wbt-server
5985/tcp  open     wsman
MAC Address: 02:6D:84:0D:70:79 (Unknown)
```
```
Nmap scan report for 10.0.10.44
Host is up (0.0034s latency).

PORT      STATE    SERVICE
3389/tcp  open     ms-wbt-server
```

```
nmap --script "rdp-enum-encryption or rdp-vuln-ms12-020 or rdp-ntlm-info" -p 3389 -T4 10.0.10.11
Starting Nmap 7.95 ( https://nmap.org ) at 2025-03-28 10:08 UTC
Nmap scan report for 10.0.10.11
Host is up (0.0048s latency).

PORT     STATE SERVICE
3389/tcp open  ms-wbt-server
| rdp-ntlm-info: 
|   Target_Name: PLUMETECH
|   NetBIOS_Domain_Name: PLUMETECH
|   NetBIOS_Computer_Name: DC1
|   DNS_Domain_Name: PLUMETECH.LOCAL
|   DNS_Computer_Name: DC1.PLUMETECH.LOCAL
|   DNS_Tree_Name: PLUMETECH.LOCAL
|   Product_Version: 10.0.20348
|_  System_Time: 2025-03-28T10:08:08+00:00
| rdp-enum-encryption: 
|   Security layer
|     CredSSP (NLA): SUCCESS
|     CredSSP with Early User Auth: SUCCESS
|_    RDSTLS: SUCCESS

Nmap done: 1 IP address (1 host up) scanned in 6.87 seconds
                                                                                                                                                            
nmap --script "rdp-enum-encryption or rdp-vuln-ms12-020 or rdp-ntlm-info" -p 3389 -T4 10.0.10.29
Starting Nmap 7.95 ( https://nmap.org ) at 2025-03-28 10:08 UTC
Nmap scan report for 10.0.10.29
Host is up (0.00015s latency).

PORT     STATE SERVICE
3389/tcp open  ms-wbt-server
| rdp-ntlm-info: 
|   Target_Name: PLUMETECH
|   NetBIOS_Domain_Name: PLUMETECH
|   NetBIOS_Computer_Name: CLI1
|   DNS_Domain_Name: PLUMETECH.LOCAL
|   DNS_Computer_Name: CLI1.PLUMETECH.LOCAL
|   DNS_Tree_Name: PLUMETECH.LOCAL
|   Product_Version: 10.0.20348
|_  System_Time: 2025-03-28T10:08:44+00:00
| rdp-enum-encryption: 
|   Security layer
|     CredSSP (NLA): SUCCESS
|     CredSSP with Early User Auth: SUCCESS
|_    RDSTLS: SUCCESS
MAC Address: 02:6D:84:0D:70:79 (Unknown)

Nmap done: 1 IP address (1 host up) scanned in 1.67 seconds
```

```
nmap -sS -T2 --max-retries 1 --scan-delay 1s -p 21,22,23,25,53,80,110,135,139,443,445,1433,1521,3306,3389,5900,5985,5986,47808 -Pn -n 10.0.10.12   
Starting Nmap 7.95 ( https://nmap.org ) at 2025-03-28 10:15 UTC
Nmap scan report for 10.0.10.12
Host is up (0.0026s latency).

PORT      STATE    SERVICE
22/tcp    open     ssh
80/tcp    open     http
135/tcp   open     msrpc
139/tcp   open     netbios-ssn
445/tcp   open     microsoft-ds
3389/tcp  open     ms-wbt-server
5985/tcp  open     wsman

```


```
No results:
10.0.10.17
10.0.10.45
10.0.10.60
```

## ARP fingerprint van de router:
#### Router
```
sudo arp-fingerprint 10.0.10.17
10.0.10.17      11110000000     Linux 2.0, MacOS 10.4, IPSO 3.2.1, Minix 3, Cisco VPN Concentrator 4.7, Catalyst 1900, BeOS, WIZnet W5100
```
#### Windows Domain controller
```
sudo arp-fingerprint 10.0.10.29
10.0.10.29      11110000000     Linux 2.0, MacOS 10.4, IPSO 3.2.1, Minix 3, Cisco VPN Concentrator 4.7, Catalyst 1900, BeOS, WIZnet W5100
```
## Active Directory
```
smbclient -U '%' -L //<DC IP> && smbclient -U 'guest%' -L //
```
https://hacktricks.boitatech.com.br/pentesting/pentesting-ldap

https://github.com/danielmiessler/SecLists/tree/master


# OT

Phoenix Contact PLC: `AXC F 2152` https://www.phoenixcontact.com/en-nl/products/controller-axc-f-2152-2404267

Programming software: `PLCnext Engineer` https://www.phoenixcontact.com/en-pc/products/software-plcnext-engineer-1046008

Application interface: `OPC UA`

Phoenix Contact axc-f 5152
https://www.agilicus.com/anyx-guide/phoenix-contact-plcnext-axc-f-2152/

Web-based management interface user: `admin`

Password is printed on the PLC: `aa3975c8`

MAC `A8:74:1D:11:BC:1D`




# From the logs, NTLM errors:
```
Successful Remote Logon Detected - User:\ANONYMOUS LOGON - NTLM authentication, possible pass-the-hash attack - Possible RDP connection. Verify that KALI is allowed to perform RDP connections
Successful Remote Logon Detected - User:\CLI1$ - NTLM authentication, possible pass-the-hash attack - Possible RDP connection. Verify that CLI1 is allowed to perform RDP connections'
```

```
$ curl -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36' 10.0.10.11:80
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>IIS Windows Server</title>
<style type="text/css">
<!--
body {
        color:#000000;
        background-color:#0072C6;
        margin:0;
}

#container {
        margin-left:auto;
        margin-right:auto;
        text-align:center;
        }

a img {
        border:none;
}

-->
</style>
</head>
<body>
<div id="container">
<a href="http://go.microsoft.com/fwlink/?linkid=66138&amp;clcid=0x409"><img src="iisstart.png" alt="IIS" width="960" height="600" /></a>
</div>
</body>
</html>
```


```
$ nxc smb 10.0.10.29 -u sabrina martin jack alice -p ./2023-200_most_used_passwords.txt
[...]
SMB         10.0.10.29      445    CLI1             [+] PLUMETECH.LOCAL\alice:Demo@123
```


```
$ smbclient --workgroup 'PLUMETECH.LOCAL' -U 'alice%Demo@123' -L //10.0.10.29

        Sharename       Type      Comment
        ---------       ----      -------
        ADMIN$          Disk      Remote Admin
        C$              Disk      Default share
        IPC$            IPC       Remote IPC
Reconnecting with SMB1 for workgroup listing.
do_connect: Connection to 10.0.10.29 failed (Error NT_STATUS_RESOURCE_NAME_NOT_FOUND)
Unable to connect with SMB1 -- no workgroup available

┌──(kali㉿kali)-[~]
└─$ smbclient --workgroup 'PLUMETECH.LOCAL' -U 'alice%Demo@123' -L //10.0.10.29

┌──(kali㉿kali)-[~]
└─$ evil-winrm -i 10.0.10.29 -u administrator -p theworldinyourhand

┌──(kali㉿kali)-[~]
└─$ smbclient -U 'alice%Demo@123' -L \\10.0.10.11
┌──(kali㉿kali)-[~]
└─$ smbclient -U 'alice%Demo@123' -L //10.0.10.11
        Sharename       Type      Comment
        ---------       ----      -------
        ADMIN$          Disk      Remote Admin
        C$              Disk      Default share
        CertEnroll      Disk      Active Directory Certificate Services share
        IPC$            IPC       Remote IPC
        NETLOGON        Disk      Logon server share
        SYSVOL          Disk      Logon server share
Reconnecting with SMB1 for workgroup listing.
do_connect: Connection to 10.0.10.11 failed (Error NT_STATUS_RESOURCE_NAME_NOT_FOUND)
Unable to connect with SMB1 -- no workgroup available

┌──(kali㉿kali)-[~]
└─$ smbclient -U 'alice%Demo@123' -L //10.0.10.12
session setup failed: NT_STATUS_LOGON_FAILURE
```

### RDP
Forward the rdp port from 10.0.10.29, 
```
./connect.sh -L 3389:10.0.10.29:3389
```
then run stuff below:

```bash
 xfreerdp /u:alice /p:Demo@123 /v:localhost /dynamic-resolution
[11:50:03:587] [23888:23889] [WARN][com.freerdp.crypto] - Certificate verification failure 'self-signed certificate (18)' at stack position 0
[11:50:03:587] [23888:23889] [WARN][com.freerdp.crypto] - CN = CLI1.PLUMETECH.LOCAL
[11:50:03:588] [23888:23889] [ERROR][com.freerdp.crypto] - The host key for localhost:3389 has changed
[11:50:03:588] [23888:23889] [ERROR][com.freerdp.crypto] - @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
[11:50:03:588] [23888:23889] [ERROR][com.freerdp.crypto] - @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
[11:50:03:588] [23888:23889] [ERROR][com.freerdp.crypto] - @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
[11:50:03:588] [23888:23889] [ERROR][com.freerdp.crypto] - IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
[11:50:03:588] [23888:23889] [ERROR][com.freerdp.crypto] - Someone could be eavesdropping on you right now (man-in-the-middle attack)!
[11:50:03:588] [23888:23889] [ERROR][com.freerdp.crypto] - It is also possible that a host key has just been changed.
[11:50:03:588] [23888:23889] [ERROR][com.freerdp.crypto] - The fingerprint for the host key sent by the remote host is 56:db:4e:f3:9f:52:a8:64:dc:94:13:e0:aa:32:90:e1:74:49:f1:a9:38:e8:81:d2:7a:f3:4d:d7:e6:1e:c8:82
[11:50:03:588] [23888:23889] [ERROR][com.freerdp.crypto] - Please contact your system administrator.
[11:50:03:588] [23888:23889] [ERROR][com.freerdp.crypto] - Add correct host key in /home/lammersj/.config/freerdp/known_hosts2 to get rid of this message.
[11:50:03:588] [23888:23889] [ERROR][com.freerdp.crypto] - Host key for localhost has changed and you have requested strict checking.
[11:50:03:588] [23888:23889] [ERROR][com.freerdp.crypto] - Host key verification failed.
!!!Certificate for localhost:3389 (RDP-Server) has changed!!!

New Certificate details:
        Common Name: CLI1.PLUMETECH.LOCAL
        Subject:     CN = CLI1.PLUMETECH.LOCAL
        Issuer:      CN = CLI1.PLUMETECH.LOCAL
        Thumbprint:  56:db:4e:f3:9f:52:a8:64:dc:94:13:e0:aa:32:90:e1:74:49:f1:a9:38:e8:81:d2:7a:f3:4d:d7:e6:1e:c8:82

Old Certificate details:
        Subject:     CN = DC1.PLUMETECH.LOCAL
        Issuer:      CN = DC1.PLUMETECH.LOCAL
        Thumbprint:  39:19:6d:99:e4:6c:36:8d:90:1f:84:f8:17:90:76:d5:38:77:1f:88:58:59:a8:7c:4f:2e:db:0a:a4:f9:4a:f8

The above X.509 certificate does not match the certificate used for previous connections.
This may indicate that the certificate has been tampered with.
Please contact the administrator of the RDP server and clarify.
Do you trust the above certificate? (Y/T/N) Y
[11:50:06:869] [23888:23889] [INFO][com.freerdp.gdi] - Local framebuffer format  PIXEL_FORMAT_BGRX32
[11:50:06:869] [23888:23889] [INFO][com.freerdp.gdi] - Remote framebuffer format PIXEL_FORMAT_BGRA32
[11:50:06:015] [23888:23889] [INFO][com.freerdp.channels.rdpsnd.client] - [static] Loaded fake backend for rdpsnd
[11:50:06:015] [23888:23889] [INFO][com.freerdp.channels.drdynvc.client] - Loading Dynamic Virtual Channel rdpgfx
[11:50:06:015] [23888:23889] [INFO][com.freerdp.channels.drdynvc.client] - Loading Dynamic Virtual Channel disp
[11:50:08:631] [23888:23889] [INFO][com.freerdp.client.x11] - Logon Error Info LOGON_FAILED_OTHER [LOGON_MSG_SESSION_CONTINUE]
```
<media-tag src="https://files.cryptpad.fr/blob/fc/fc76feba477da52d461bdeb0c27e97e98801938c78b1ff6f" data-crypto-key="cryptpad:GLPD8iqHUsrxR8ejx5SnrTrn3e25AtP78ejQSTyUzyA="></media-tag>

## From the RDP session:




