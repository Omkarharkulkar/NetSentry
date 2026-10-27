# NetSentry — Network Discovery & Security Assessment Lab

## Project Overview

NetSentry is a hands-on network security assessment lab built using Kali Linux and Ubuntu virtual machines. It demonstrates host discovery, TCP port scanning, service identification, network traffic capture, and technical reporting in an isolated VirtualBox network.

## Objectives

- Discover active hosts on a private lab subnet.
- Identify open TCP ports and exposed services.
- Perform service and version detection using Nmap.
- Capture and inspect network traffic using Wireshark.
- Document findings and practical security recommendations.

## Lab Architecture

| Component | Configuration |
|---|---|
| Analyst machine | Kali Linux |
| Target machine | Ubuntu 24.04.5 LTS |
| Lab network | 192.168.50.0/24 |
| Kali lab IP | 192.168.50.10 |
| Ubuntu lab IP | 192.168.50.20 |
| Network isolation | VirtualBox Internal Network |
| Scanning tool | Nmap 7.94SVN |
| Packet analysis | Wireshark 4.2.0 |

## Assessment Workflow

1. Configure isolated connectivity between the analyst and target VMs.
2. Discover active hosts with Nmap.
3. Scan all TCP ports and identify services.
4. Generate ICMP and SSH traffic for packet inspection.
5. Capture traffic in Wireshark.
6. Document results, limitations, and recommendations.

## Key Results

- Discovered two active hosts on the lab subnet.
- Scanned all 65,535 TCP ports on the Ubuntu target.
- Identified SSH on TCP port 22.
- Detected the reported service version: OpenSSH 9.6p1 Ubuntu 3ubuntu13.20.
- Found no other open TCP ports during the full scan.
- Captured ICMP and SSH-related traffic in Wireshark.
- Produced an initial network security assessment report.

## Repository Structure

```text
NetSentry/
├── evidence/
│   ├── ssh-service-scan.txt
│   ├── full-tcp-scan.txt
│   └── netsentry-lab-traffic.pcapng
├── reports/
│   └── initial-assessment-report.txt
└── README.md
```

## Tools and Technologies

- Kali Linux
- Ubuntu 24.04.5 LTS
- Oracle VirtualBox
- Nmap
- Wireshark
- Linux networking and command-line utilities

## Screenshots

### 1. Network Host Discovery
![Nmap host discovery](screenshots/01-host-discovery.png)

### 2. Full TCP Port Scan
![Full TCP port scan](screenshots/02-full-tcp-scan.png)

### 3. Wireshark Traffic Capture
![Wireshark network traffic](screenshots/03-wireshark-traffic.png)

### 4. Initial Assessment Report
![Initial assessment report](screenshots/04-assessment-report.png)

## Security Scope

All scanning and packet capture were performed against the author's own Ubuntu virtual machine on an isolated lab network. The assessment covered TCP ports and selected network traffic; it did not constitute a comprehensive vulnerability assessment.

## Future Improvements

- Review SSH configuration and authentication security.
- Add repeatable scan and evidence-collection scripts.
- Conduct controlled UDP service discovery.
- Add screenshots and structured findings with severity and remediation.
- Expand the lab with additional authorized targets and detection exercises.

## Disclaimer

This project is intended for education and authorized security testing. Scan only systems for which you have permission.
