#!/usr/bin/env bash

# NetSentry - Repeatable Network Assessment
# Intended for the isolated NetSentry lab network.

set -u
set -o pipefail

TARGET="${1:-192.168.50.20}"
LAB_PREFIX="192.168.50."
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# Accept only valid individual IPv4 targets in the lab subnet.
# Leading zeros are rejected to avoid ambiguous address formats.
if [[ ! "$TARGET" =~ ^192\.168\.50\.(0|[1-9][0-9]{0,2})$ ]]; then
    echo "ERROR: Target must be a valid IPv4 address in 192.168.50.0/24."
    exit 2
fi

LAST_OCTET="${TARGET##*.}"

if (( 10#$LAST_OCTET < 1 || 10#$LAST_OCTET > 254 )); then
    echo "ERROR: Target must be a usable host address (.1 to .254)."
    exit 2
fi

if [[ "$TARGET" == "192.168.50.10" ]]; then
    echo "ERROR: The target cannot be the Kali scanner itself."
    exit 2
fi

for tool in nmap ping timeout sha256sum; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "ERROR: Required command not found: $tool"
        exit 2
    fi
done

OUT_DIR="reports/runs/${TIMESTAMP}_${TARGET//./_}"
mkdir -p "$OUT_DIR" || {
    echo "ERROR: Could not create output directory."
    exit 2
}

REPORT="$OUT_DIR/assessment-summary.txt"
SCAN="$OUT_DIR/tcp-scan.txt"

{
    echo "=================================================="
    echo "          NETSENTRY NETWORK ASSESSMENT"
    echo "=================================================="
    echo "Date:       $(date --iso-8601=seconds)"
    echo "Scanner:    $(hostname)"
    echo "Target:     $TARGET"
    echo "Scope:      TCP ports 1-1000"
    echo "Scan type:  TCP connect scan"
    echo

    echo "----- REACHABILITY CHECK -----"
    if ping -c 2 -W 2 "$TARGET"; then
        echo "Ping result: Replies received."
    else
        echo "Ping result: No replies received."
        echo "Note: ICMP may be blocked; TCP scan will still be attempted."
    fi

    echo
    echo "----- TCP PORT SCAN -----"
    echo "Starting Nmap scan at $(date --iso-8601=seconds)"

    if timeout 120 nmap -sT -Pn -n -p 1-1000 --reason \
        -oN "$SCAN" "$TARGET"; then
        SCAN_STATUS=0
        echo "Scan status: Completed."
    else
        SCAN_STATUS=$?
        echo "Scan status: Failed or timed out (exit code $SCAN_STATUS)."
    fi

    echo
    echo "----- SCAN OUTPUT -----"
    if [[ -f "$SCAN" ]]; then
        cat "$SCAN"
    else
        echo "No Nmap output file was produced."
    fi

    echo
    echo "----- EVIDENCE CHECKSUM -----"
    if [[ -f "$SCAN" ]]; then
        sha256sum "$SCAN"
    else
        echo "Checksum unavailable: scan output file is missing."
    fi

    echo
    echo "Report directory: $OUT_DIR"
    echo "=================================================="
} > "$REPORT" 2>&1

REPORT_STATUS=$?
cat "$REPORT"

if (( REPORT_STATUS != 0 )); then
    echo "ERROR: Could not complete report generation."
    exit 1
fi

if (( SCAN_STATUS != 0 )); then
    exit "$SCAN_STATUS"
fi

exit 0
