# NetSentry — Network Discovery & Security Assessment Lab

## Project Overview

NetSentry is a hands-on network discovery and security assessment lab built with Kali Linux and Ubuntu virtual machines. The project focuses on identifying active hosts, examining TCP ports and services, capturing network traffic, and documenting security observations.

The lab also compares scanner-side results with packet-level evidence collected on the target machine. This helps explain how network scanning appears from both sides and why packet captures and authentication logs can provide different information.

All testing is performed in an isolated VirtualBox lab network.

## Objectives

- Discover active hosts on a private lab subnet.
- Identify open and closed TCP ports.
- Perform service and version detection using Nmap.
- Capture and inspect network traffic using Wireshark and tcpdump.
- Compare remote scan results with defender-side packet evidence.
- Review relevant service and authentication logs.
- Document findings, limitations, and practical recommendations.

## Lab Architecture

| Component | Configuration |
|---|---|
| Analyst machine | Kali Linux |
| Target machine | Ubuntu 24.04.5 LTS |
| Lab network | `192.168.50.0/24` |
| Kali lab IP | `192.168.50.10` |
| Ubuntu lab IP | `192.168.50.20` |
| Network isolation | VirtualBox Internal Network |
| Scanning tool | Nmap 7.94SVN |
| Packet analysis | Wireshark and tcpdump |
| Capture analysis | TShark |

Both VMs also have a separate NAT interface for internet connectivity. The internal network is used for NetSentry lab traffic.

## Assessment Workflow

1. Configure isolated connectivity between Kali and Ubuntu.
2. Discover active hosts on the lab subnet.
3. Scan all TCP ports on the target and identify exposed services.
4. Generate selected ICMP and SSH traffic for packet inspection.
5. Capture and inspect network traffic.
6. Run a controlled TCP SYN scan against ports 1–1000.
7. Capture the same scan from the Ubuntu target.
8. Compare Nmap results with packet-level responses.
9. Review SSH and authentication logs for relevant events.
10. Document findings, evidence, limitations, and recommendations.

## Repeatable Network Assessment

NetSentry includes a Bash script to make basic network checks easier to repeat. It checks target reachability, scans TCP ports 1–1000, and saves the results in a timestamped directory.

### Run the assessment

From the Kali VM:

```bash
./scripts/network_assessment.sh 192.168.50.20
```

The target must be a valid host address in the isolated NetSentry lab subnet (`192.168.50.0/24`). The script rejects malformed addresses, out-of-scope targets, and the scanner's own IP address.

### Generated evidence

Each run creates a separate directory under `reports/runs/`, containing:

- `assessment-summary.txt` — reachability results, scan output, and evidence checksum.
- `tcp-scan.txt` — the Nmap output for TCP ports 1–1000.

The script uses a TCP connect scan. A failed ping does not automatically stop the TCP scan, since ICMP responses may be blocked while TCP services remain reachable.

### Run the tests

```bash
./tests/test_network_assessment.sh
```

The tests check Bash syntax and verify that invalid, out-of-scope, and scanner-self targets are rejected.

### Scope and limitations

This script performs a limited TCP assessment, not a full vulnerability assessment. It does not scan UDP ports, establish that a service is vulnerable, or determine whether observed activity is malicious. Results reflect the target's state at the time of the scan.

## Key Results

- Discovered two active hosts on the lab subnet.
- Scanned all 65,535 TCP ports on the Ubuntu target during the initial assessment.
- Identified SSH on TCP port 22.
- Observed the reported service version: OpenSSH 9.6p1 Ubuntu 3ubuntu13.20.
- Found no other open TCP ports during the initial full-port scan.
- Captured ICMP and SSH-related traffic for analysis.
- Captured a controlled TCP SYN scan from the target's perspective.
- Confirmed that the defender-side capture showed SYN probes, SYN-ACK responses for TCP/22, and reset responses for closed ports.
- Compared the network evidence with the reviewed SSH and authentication logs.
- Produced initial and defender-side assessment reports.

These results describe the lab at the time of testing. They do not establish that the target is free of vulnerabilities.

## Defender-Side Analysis

The defender-side exercise used Kali (`192.168.50.10`) to scan Ubuntu (`192.168.50.20`) across TCP ports 1–1000.

Nmap reported one open port, TCP/22, and 999 closed ports. The packet capture collected on Ubuntu independently showed the corresponding TCP probe and response patterns.

| Observation | Interpretation |
|---|---|
| TCP SYN probes from Kali | Consistent with the controlled Nmap SYN scan |
| SYN-ACK from TCP/22 | Indicates that the SSH port was accepting TCP connection requests |
| RST-ACK responses from closed ports | Indicates that the target rejected connection attempts on those ports |
| Reset from Kali after the SYN-ACK | Consistent with SYN-scan behaviour rather than a completed TCP connection |
| No corresponding SSH authentication event observed in the reviewed logs | Expected for a scan that did not proceed to SSH user authentication |

This exercise demonstrates that network activity may be visible in packet captures without producing a corresponding SSH authentication event.

The absence of an authentication event in the reviewed output does not mean that the activity was invisible to every host or network monitoring mechanism.

## Findings and Recommendations

### Finding 1: SSH is reachable on the lab interface

**Evidence:** Nmap scan results and the defender-side packet capture.

**Recommendation:** Keep SSH enabled only where needed and restrict access to trusted sources where practical.

### Finding 2: Closed ports returned TCP reset responses

**Evidence:** The target-side packet capture.

**Recommendation:** Compare remote scan results with local listening sockets and applicable firewall rules to understand which services are actually exposed.

### Finding 3: Network evidence and authentication logs provide different views

**Evidence:** TCP probes and responses were captured, while no corresponding SSH authentication event was observed in the reviewed logs.

**Recommendation:** Correlate network and host evidence when investigating scanning or connection activity.

### Finding 4: The repeatable assessment identified one open TCP port in the scanned range

**Evidence:** The October 29, 2026 assessment of 192.168.50.20 reported TCP/22 open and 999 other TCP ports closed across ports 1–1000. The saved scan output and its SHA-256 checksum are available in the generated assessment report.

**Interpretation:** SSH was reachable during this assessment. The result does not establish whether the service is vulnerable, whether its configuration is secure, or what services may exist outside the scanned range.

**Recommendation:** Review the SSH configuration and access requirements on the Ubuntu target. If further assessment is needed, document the scope and compare results before and after any controlled configuration change.

These are observations from controlled lab exercises, not proof of malicious activity or a confirmed vulnerability.

## Repository Structure

```text
NetSentry/
├── evidence/
│   ├── full-tcp-scan.txt
│   ├── ssh-service-scan.txt
│   ├── netsentry-lab-traffic.pcapng
│   ├── defender-tcp-scan.txt
│   └── defender-scan-capture.pcap
├── reports/
│   ├── initial-assessment-report.txt
│   ├── defender-side-analysis.txt
│   ├── sample-run/
│   │   ├── assessment-summary.txt
│   │   └── tcp-scan.txt
│   └── runs/                  # Generated locally; ignored by Git
├── scripts/
│   └── network_assessment.sh
├── tests/
│   └── test_network_assessment.sh
├── screenshots/
│   ├── 01-host-discovery.png
│   ├── 02-full-tcp-scan.png
│   ├── 03-wireshark-traffic.png
│   ├── 04-assessment-report.png
│   └── 05-defender-side-analysis.png
├── .gitignore
└── README.md
```

## Tools and Technologies

- Kali Linux
- Ubuntu 24.04.5 LTS
- Oracle VirtualBox
- Nmap
- Wireshark
- TShark
- tcpdump
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

### 5. Defender-Side Packet Analysis

![Defender-side packet analysis](screenshots/05-defender-side-analysis.png)

## Limitations

- The initial assessment covered TCP ports; UDP was not comprehensively assessed.
- The defender-side scan covered TCP ports 1–1000, not every possible port.
- Service version information does not, by itself, prove a vulnerability.
- A port scan does not establish malicious intent.
- Authentication-log observations are limited to the logs and time ranges reviewed.
- The lab does not implement a complete SIEM, alerting, or incident-response pipeline.

## Future Improvements

- Review SSH configuration and document a controlled hardening change.
- Compare assessment results before and after the hardening change.
- Add a structured assessment report with severity, evidence, impact, and remediation.
- Explore additional authorized network troubleshooting scenarios.
- Document the assessment script's failure-handling tests and their results.

## Disclaimer

This project is intended for education and authorized security testing. Only scan systems for which you have permission. All current testing is conducted against the author's own virtual machines in an isolated lab network.
