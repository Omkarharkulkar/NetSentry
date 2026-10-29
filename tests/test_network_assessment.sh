#!/usr/bin/env bash

# Tests for the NetSentry network assessment script.

set -u

SCRIPT="scripts/network_assessment.sh"
PASSED=0
FAILED=0

pass() {
    echo "[PASS] $1"
    PASSED=$((PASSED + 1))
}

fail() {
    echo "[FAIL] $1"
    FAILED=$((FAILED + 1))
}

if bash -n "$SCRIPT"; then
    pass "Assessment script has valid Bash syntax"
else
    fail "Assessment script has valid Bash syntax"
fi

check_rejected() {
    local target="$1"
    local description="$2"
    local output
    local status

    output=$(bash "$SCRIPT" "$target" 2>&1)
    status=$?

    if (( status != 0 )); then
        pass "$description"
    else
        fail "$description"
    fi
}

check_rejected "192.168.1.1" \
    "Rejects targets outside the lab subnet"

check_rejected "192.168.50.999" \
    "Rejects an out-of-range IPv4 octet"

check_rejected "192.168.50.1.2" \
    "Rejects an address with too many octets"

check_rejected "192.168.50.abc" \
    "Rejects a non-numeric address"

check_rejected "192.168.50.01" \
    "Rejects an address with a leading zero"

check_rejected "192.168.50.0" \
    "Rejects the subnet address"

check_rejected "192.168.50.255" \
    "Rejects the broadcast address"

check_rejected "192.168.50.10" \
    "Rejects the Kali scanner's own address"

echo
echo "========== TEST SUMMARY =========="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if (( FAILED > 0 )); then
    exit 1
fi

exit 0
