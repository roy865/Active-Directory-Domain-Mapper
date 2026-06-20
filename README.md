# Active Directory Domain Mapper

## Overview
This bash script automates Active Directory enumeration and vulnerability testing[cite: 11]. Developed during my cybersecurity studies in the Network Security course (ZX305), it is designed as an educational proof-of-concept to demonstrate how networks are mapped and techniques are chained against AD environments[cite: 11].

## Key Features
* **Progressive Network Scanning:** Utilizes Nmap for staged network reconnaissance, offering basic, mid, and high-level (including UDP) scanning modes[cite: 11].
* **Automated AD Enumeration:** Extracts Domain Controller and DHCP information, and uses `crackmapexec` to enumerate SMB shares, active users, groups, and password policies[cite: 11].
* **Simulated Exploitation Vectors:** Demonstrates common AD attack paths, including password spraying via `crackmapexec` and Kerberoasting ticket requests using `impacket-GetUserSPNs`[cite: 11].
* **Automated PDF Reporting:** Compiles all findings, scan logs, and extracted AD data into a structured output file (`Domain_Mission_Report.pdf`)[cite: 11].

## Ecosystem Impact
This project serves as a hands-on learning resource for understanding Active Directory vulnerabilities. By sharing this tool, I hope to assist other security students in safely navigating and testing AD environments using industry-standard tools within their lab environments.
