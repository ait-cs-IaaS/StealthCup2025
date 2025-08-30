# Setup

Apart from the registry keys to enable dumping LDAP requests in event logs, the script `Write-LDAPQueryLog.ps1` which analyzes and transforms LDAP queries ingestable to Wazuh must run at least every minute on a domain controller. 

Per default the script writes data to `%PROGRAMDATA%\AIT` and the script should reside in `%PROGRAMFILES\AIT`. It saves a timestamp of its last execution in the registry key `HKLM:\SOFTWARE\AIT\LDAPQueryLogParser\LastRun`. This timestamp is used to determine which logs are new and have not yet been analyzed to ensure no duplicates are generated.

On the Wazuh server the custom decoder `LDAPQueryLogParser_decoder.xml` must be deployed in the custom decoder folder `/var/ossec/etc/decoders/`.