|attack description|team4|team5|team6|team7|team8|team9|team10|team11|team12|expected result|
|------------------|-----|-----|-----|-----|-----|-----|------|------|------|------|
|Wazuh agents registered and sending|OK|OK|suricata missing|OK|||OK||||
|tests.sh|OK|OK|OK|OK|FAIL|FAIL username mismatch website|FAIL|OK|OK|6 crits apart from as-rep (variable amount)|
|ESC8|FAIL|FAIL|FAIL|FAIL|OK|-|OK|OK|OK|Relaying alerted|
|DA plumber|OK|OK|OK|OK|OK|-|OK|OK|OK|New Domain Admin alerted|
|crack pwd of JUMP-RDP user|fernando:p9ekfmsa|roderick:knorrecool!|joe:ahoy441mid379|jimmy:c0pperm0e|||||||
|RDP to CLI1|OK|OK|OK|OK|OK|-|OK|OK|OK||
|contents IT fileshare|OK|OK|OK|OK|OK|-|OK|OK|OK||
|RDP to JUMP|OK|OK|OK|OK|OK|-|FAIL|OK|OK||
|LPE on JUMP|OK|OK|OK|OK|OK|-|-|OK|OK|Alteration on Backup-Job alerted|
|Dump KeePass on JUMP|OK|OK|OK|OK|OK|-|-|OK|OK|Process dumping alerted|
|Key from KeePass Dump|FAIL|FAIL|FAIL|FAIL|OK|-|-|OK|OK|KeePass password could be recovered| KeePass instance in wrong state in 4-7
|RDP to ENG1|OK|OK|OK|OK|OK|-|-|OK|OK||
|contents OT fileshare|||||FAIL|-|-|FAIL|FAIL||
|SSH to hist|FAIL|FAIL|FAIL|FAIL||-|-|FAIL|FAIL|logon from admin alerted| no logs from hist received
|Set Coil in python|OK|OK|OK|OK||-|-|OK|OK|connection on port 420 alerted| alert set to medium -> raise severity
|Set Coil in PLCEngineer|OK|OK|OK|OK|||||||
||||||||||||
||||||||||||
||||||||||||
||||||||||||
||||||||||||
||||||||||||
||||||||||||


- FAIL tests.sh team8: last line of whisker output was: Found Credential: DC1$:[-] No TGT found from ccache, did you set the KRB5CCNAME environment variable?
- FAIL tests.sh team10: pywhisker shows usage output, wrong parameters maybe
- FAIL RDP to JMP in team10: Error in name reoslution: `Pinging jump.plumetech-ot.local [10.0.27.44]`

- suricata rule 1341 trigges way too often (~70k per half hour)
- rule 1340 triggers when coil is written from HIST to PLC1, in team8 1336 triggered correctly