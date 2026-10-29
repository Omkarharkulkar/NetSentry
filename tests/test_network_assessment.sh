#!/usr/bin/env bash

# Tests for the NetSentry network assessment script.
# Mock commands are used to avoid real network scans.

set -u

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/scripts/network_assessment.sh"
PASSED=0
FAILED=0

TEST_DIR="$(mktemp -d)" || exit 1
MOCK_BIN="$TEST_DIR/bin"
WORK_DIR="$TEST_DIR/work"
MOCK_NMAP_MARKER="$TEST_DIR/nmap-called"

mkdir -p "$MOCK_BIN" "$WORK_DIR"
export MOCK_NMAP_MARKER

cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

pass() {
    echo "[PASS] $1"
    PASSED=$((PASSED + 1))
}

fail() {
    echo "[FAIL] $1"
    FAILED=$((FAILED + 1))
}

# Mock ping so the test never sends network packets.
cat > "$MOCK_BIN/ping" <<'MOCK_PING'
#!/usr/bin/env bash
echo "Mock ping: simulated replies."
exit 0
MOCK_PING

# Mock Nmap so the test never performs a real scan.
cat > "$MOCK_BIN/nmap" <<'MOCK_NMAP'
#!/usr/bin/env bash

printf 'called\n' >> "$MOCK_NMAP_MARKER"

OUTPUT_FILE=""

while (($#)); do
    if [[ "$1" == "-oN" ]]; then
        shift
        OUTPUT_FILE="${1:-}"
    fi
    shift
done

if [[ -z "$OUTPUT_FILE" ]]; then
    echo "Mock Nmap: missing output path." >&2
    exit 2
fi

printf '%s\n' \
    "Mock Nmap scan report" \
    "Host is up." \
    "22/tcp open ssh" > "$OUTPUT_FILE"

exit 0
MOCK_NMAP

chmod +x "$MOCK_BIN/ping" "$MOCK_BIN/nmap"

if bash -n "$SCRIPT"; then
    pass "Assessment script has valid Bash syntax"
else
    fail "Assessment script has valid Bash syntax"
fi

if bash -n "$0"; then
    pass "Test script has valid Bash syntax"
else
    fail "Test script has valid Bash syntax"
fi

check_rejected() {
    local target="$1"
    local description="$2"
    local output
    local status

    rm -f "$MOCK_NMAP_MARKER"

    if output=$(PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" "$target" 2>&1); then
        status=0
    else
        status=$?
    fi

    if (( status != 0 )); then
        pass "$description"
    else
        fail "$description"
    fi

    if [[ ! -e "$MOCK_NMAP_MARKER" ]]; then
        pass "Does not invoke Nmap for rejected target: $target"
    else
        fail "Does not invoke Nmap for rejected target: $target"
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
echo "========== MOCK ASSESSMENT TEST =========="

rm -f "$MOCK_NMAP_MARKER"

if (
    cd "$WORK_DIR" &&
    PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" 192.168.50.20
) > "$TEST_DIR/assessment-output.txt" 2>&1; then
    pass "Accepts a valid lab target and completes the mock assessment"
else
    fail "Accepts a valid lab target and completes the mock assessment"
fi

if [[ -f "$MOCK_NMAP_MARKER" ]]; then
    pass "Invokes the mock Nmap command for a valid target"
else
    fail "Invokes the mock Nmap command for a valid target"
fi

SUMMARY_FILE="$(
    find "$WORK_DIR/reports/runs" \
        -name assessment-summary.txt -print -quit 2>/dev/null
)"
SCAN_FILE="$(
    find "$WORK_DIR/reports/runs" \
        -name tcp-scan.txt -print -quit 2>/dev/null
)"

if [[ -n "$SUMMARY_FILE" && -f "$SUMMARY_FILE" ]] &&
   grep -q 'Target:     192.168.50.20' "$SUMMARY_FILE"; then
    pass "Generates an assessment summary for the requested target"
else
    fail "Generates an assessment summary for the requested target"
fi

if [[ -n "$SCAN_FILE" && -f "$SCAN_FILE" ]] &&
   grep -q '22/tcp open ssh' "$SCAN_FILE"; then
    pass "Saves the mock scan output to the evidence file"
else
    fail "Saves the mock scan output to the evidence file"
fi

echo
echo "========== TEST SUMMARY =========="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if (( FAILED > 0 )); then
    exit 1
fi

exit 0
