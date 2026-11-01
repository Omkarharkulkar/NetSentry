# NetSentry — Defender-Side Analysis

**Assessment date:** 28 October 2026  
**Scanner:** Kali Linux (`192.168.50.10`)  
**Target:** Ubuntu 24.04.5 (`192.168.50.20`)  
**Lab network:** NetSentry-Lab (`192.168.50.0/24`)

## 1. Objective

Compare a controlled TCP SYN scan with packet-level evidence collected on the target machine, then review the available SSH and authentication logs.

## 2. Scan Details

- **Tool:** Nmap 7.94SVN
- **Scan type:** TCP SYN scan (`-sS`)
- **Port range:** TCP 1–1000
- **Target:** `192.168.50.20`

A SYN scan sends an initial TCP SYN probe and uses the response to classify a port. It normally does not complete the TCP handshake.

The repeatable assessment script uses a TCP connect scan (`-sT`), which asks the operating system to establish a TCP connection. These are separate assessments and use different scan methods.

## 3. Results

- **Host status:** Up
- **TCP ports scanned:** 1,000
- **Open ports:** 1
- **Closed ports:** 999
- **Open service:** TCP/22 (SSH)

The Nmap results and target-side capture agree that TCP/22 was open during this assessment.

## 4. Defender-Side Observations

The Ubuntu capture contains TCP SYN probes from `192.168.50.10` to `192.168.50.20`.

Observed response patterns include:

- SYN-ACK from TCP/22, indicating an open port.
- RST-ACK responses from closed TCP ports.
- A reset from the scanner after the SYN-ACK on TCP/22, consistent with SYN-scan behaviour.

The capture contains 2,001 packets and spans approximately 31.9 milliseconds.

## 5. Authentication Log Review

The saved authentication evidence covers selected events from 28–29 October 2026.

Relevant files:

- `evidence/auth-log-review.txt`
- `evidence/auth-log-events.txt`

The reviewed records include:

- A failed password attempt followed by a successful password login from `192.168.50.10` on 28 October.
- Intentional password and public-key authentication tests from that address on 29 October.

The 28 October password test occurred at approximately 16:34, around ten minutes after the 16:24 SYN scan. It was a separate intentional test, not evidence that the SYN scan caused an SSH login attempt.

The available records do not establish that the authentication events were caused by the recorded SYN scan. A SYN scan normally does not proceed to SSH user authentication.

These events demonstrate why packet captures and authentication logs need to be interpreted in the context of the specific test, its timing, and the available evidence. The reviewed log excerpts are not intended to represent every authentication event on the target.

## 6. Findings and Recommendations

### Finding 1 — Informational: SSH is reachable

**Evidence:** Nmap report and target-side packet capture.

**Interpretation:** TCP/22 was reachable from the scanner. This result alone does not establish a vulnerability.

**Recommendation:** Keep SSH enabled only where required and restrict access to trusted sources where practical.

### Finding 2 — Informational: Closed ports returned resets

**Evidence:** Target-side packet capture.

**Interpretation:** The target returned reset responses for ports classified as closed. This is an observed TCP response, not a vulnerability by itself.

**Recommendation:** Compare remote scan results with local listening sockets and firewall rules.

### Finding 3 — Informational: Network and authentication logs show different aspects of activity

**Evidence:** Packet capture, `evidence/auth-log-review.txt`, and `evidence/auth-log-events.txt`.

**Interpretation:** The reviewed records contain connection, authentication, and pre-authentication events from the lab scanner. The available evidence does not establish that these events were caused by the recorded SYN scan. The password and public-key tests were separate intentional lab activities.

**Recommendation:** Correlate timestamps and test steps before attributing host events to a network scan.

## 7. Evidence Files

- `evidence/defender-tcp-scan.txt`
- `evidence/defender-scan-capture.pcap`
- `evidence/auth-log-review.txt`
- `evidence/auth-log-events.txt`

**Capture SHA-256:**

`3840edec0113f107dcd0ceba1de50c3542eaecaa1ab66e98675f5cbe173e902b`

---

**End of Analysis**

Log records from 27 October were no longer available on the VM, so the version-detection scans from that date could not be compared against host authentication logs.
