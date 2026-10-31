# NetSentry — Initial Network Security Assessment Report

## 1. Assessment Overview

- **Project:** NetSentry — Network Discovery & Security Assessment Lab
- **Assessment date:** 27 October 2026
- **Assessment type:** Authorized internal lab assessment
- **Analyst platform:** Kali Linux
- **Target platform:** Ubuntu 24.04.5 LTS
- **Target IP:** `192.168.50.20`
- **Lab network:** `192.168.50.0/24`
- **Tools:** Nmap 7.94SVN, Wireshark 4.2.0

## 2. Objectives

- Discover active hosts on the isolated lab network.
- Identify exposed TCP ports and services.
- Determine the SSH service version reported by Nmap.
- Capture and inspect ICMP and SSH-related network traffic.

## 3. Host Discovery

**Command:** `sudo nmap -sn 192.168.50.0/24`

**Results:**

- Two hosts were discovered: Kali (`192.168.50.10`) and Ubuntu (`192.168.50.20`).
- Ubuntu responded to host-discovery probes.
- Kali-to-Ubuntu connectivity was verified with 0% packet loss across four ICMP echo requests.

## 4. TCP Port and Service Assessment

**Command:** `sudo nmap -p- -sV 192.168.50.20`

**Results:**

- 65,535 TCP ports scanned.
- One open TCP port identified: `22/tcp`.
- Service identified: SSH.
- Reported version: OpenSSH 9.6p1 Ubuntu 3ubuntu13.20.
- The remaining 65,534 TCP ports were reported closed.

The scan identified the service and version information reported by Nmap. This does not, by itself, establish whether the SSH service is vulnerable.

## 5. SSH Connectivity Observation

A controlled SSH connection test to the target reached the authentication stage. The supplied username and authentication methods were rejected.

This confirms that the SSH service was reachable and responding to a connection attempt. It does not establish whether the supplied username exists or whether the service is vulnerable.

## 6. Packet Capture

- **Tool:** Wireshark 4.2.0
- **Interface:** `eth1`
- **Display filter:** `ip.addr == 192.168.50.20`

**Observed traffic:**

- ICMP echo requests and replies associated with connectivity testing.
- TCP/SSH-related traffic associated with the SSH connection test.

**Capture file:** `evidence/netsentry-lab-traffic.pcapng`

## 7. Findings and Recommendations

### Finding 1 — SSH is reachable on the lab network

TCP port 22 was reachable from the Kali analyst machine.

**Recommendation:** Keep SSH enabled only where required. Review authentication settings, restrict access to trusted lab hosts, and keep the operating system and SSH package updated.

### Finding 2 — No other open TCP ports were identified

The full TCP scan found no other open TCP ports on the target at the time of assessment.

**Recommendation:** Repeat the assessment after service or configuration changes. UDP services and vulnerability status were not assessed in this scan.

### Finding 3 — Packet-level visibility was established

Wireshark captured ICMP and SSH-related traffic between the lab machines.

**Recommendation:** Preserve the capture and correlate packet observations with scan results during future investigations.

## 8. Scope and Limitations

- The assessment was limited to the isolated NetSentry lab network.
- TCP ports 1–65535 were scanned on the Ubuntu target.
- No comprehensive UDP scan was performed.
- No authenticated vulnerability assessment or comprehensive vulnerability scan was performed.
- The reported SSH version alone does not prove the presence or absence of vulnerabilities.
- Findings represent the observed state during this assessment.

## 9. Evidence Files

- `evidence/ssh-service-scan.txt`
- `evidence/full-tcp-scan.txt`
- `evidence/netsentry-lab-traffic.pcapng`

## 10. Conclusion

The assessment successfully identified the active lab hosts, discovered the exposed SSH service, completed a full TCP port scan, and captured relevant network traffic in Wireshark.

These results establish a baseline of the target's network exposure and provide evidence for subsequent security configuration reviews and controlled testing.

---

**End of Report**
