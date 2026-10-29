#!/usr/bin/env bash

# Tests for the NetSentry network assessment script.
# Mock commands prevent real network scans.

set -u

REAL_SHA256SUM="$(command -v sha256sum)" || {
    echo "[FAIL] sha256sum is required for this test suite" >&2
    exit 1
}
export REAL_SHA256SUM

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

cat > "$MOCK_BIN/ping" <<'MOCK_PING'
#!/usr/bin/env bash
echo "Mock ping: simulated replies."
exit 0
MOCK_PING

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

case "${MOCK_NMAP_MODE:-success}" in
    missing-output)
        # Simulate Nmap returning success without creating evidence.
        exit 0
        ;;
    fail)
        printf '%s\n' "Mock Nmap failed after starting." > "$OUTPUT_FILE"
        exit 7
        ;;
    success)
        printf '%s\n' \
            "Mock Nmap scan report" \
            "Host is up." \
            "22/tcp open ssh" > "$OUTPUT_FILE"
        exit 0
        ;;
    *)
        echo "Unknown mock Nmap mode." >&2
        exit 9
        ;;
esac
MOCK_NMAP

cat > "$MOCK_BIN/sha256sum" <<'MOCK_SHA256'
#!/usr/bin/env bash

if [[ "${MOCK_SHA256SUM_MODE:-success}" == "fail" ]]; then
    echo "Mock checksum failure." >&2
    exit 9
fi

exec "$REAL_SHA256SUM" "$@"
MOCK_SHA256

chmod +x "$MOCK_BIN/ping" "$MOCK_BIN/nmap" "$MOCK_BIN/sha256sum"

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
    local status

    rm -f "$MOCK_NMAP_MARKER"

    if PATH="$MOCK_BIN:$PATH" bash "$SCRIPT" "$target" \
        > "$TEST_DIR/rejected-output.txt" 2>&1; then
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

run_assessment() {
    local target="$1"
    local nmap_mode="${2:-success}"
    local checksum_mode="${3:-success}"

    (
        cd "$WORK_DIR" || exit 1
        MOCK_NMAP_MODE="$nmap_mode" \
        MOCK_SHA256SUM_MODE="$checksum_mode" \
        PATH="$MOCK_BIN:$PATH" \
            bash "$SCRIPT" "$target"
    ) > "$TEST_DIR/assessment-output.txt" 2>&1
}

check_rejected "192.168.1.1" "Rejects targets outside the lab subnet"
check_rejected "192.168.50.999" "Rejects an out-of-range IPv4 octet"
check_rejected "192.168.50.1.2" "Rejects an address with too many octets"
check_rejected "192.168.50.abc" "Rejects a non-numeric address"
check_rejected "192.168.50.01" "Rejects an address with a leading zero"
check_rejected "192.168.50.0" "Rejects the subnet address"
check_rejected "192.168.50.255" "Rejects the broadcast address"
check_rejected "192.168.50.10" "Rejects the Kali scanner's own address"

echo
echo "========== SUCCESSFUL MOCK ASSESSMENT =========="

if run_assessment "192.168.50.20"; then
    pass "Completes an assessment with successful mock commands"
else
    fail "Completes an assessment with successful mock commands"
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
    pass "Saves mock scan output to the evidence file"
else
    fail "Saves mock scan output to the evidence file"
fi

echo
echo "========== NMAP FAILURE TEST =========="

if run_assessment "192.168.50.21" "fail"; then
    fail "Returns a nonzero status when Nmap fails"
else
    pass "Returns a nonzero status when Nmap fails"
fi

if grep -q 'Scan status: Failed or timed out' \
    "$WORK_DIR"/reports/runs/*_192_168_50_21/assessment-summary.txt 2>/dev/null; then
    pass "Records the Nmap failure in the assessment summary"
else
    fail "Records the Nmap failure in the assessment summary"
fi

echo
echo "========== MISSING EVIDENCE TEST =========="

if run_assessment "192.168.50.22" "missing-output"; then
    fail "Rejects a successful Nmap exit without a scan-output file"
else
    pass "Rejects a successful Nmap exit without a scan-output file"
fi

if grep -q 'No Nmap output file was produced' \
    "$WORK_DIR"/reports/runs/*_192_168_50_22/assessment-summary.txt 2>/dev/null; then
    pass "Records the missing scan-output file in the summary"
else
    fail "Records the missing scan-output file in the summary"
fi

echo
echo "========== CHECKSUM FAILURE TEST =========="

if run_assessment "192.168.50.23" "success" "fail"; then
    fail "Returns a nonzero status when checksum generation fails"
else
    pass "Returns a nonzero status when checksum generation fails"
fi

if grep -q 'Mock checksum failure' \
    "$WORK_DIR"/reports/runs/*_192_168_50_23/assessment-summary.txt 2>/dev/null; then
    pass "Records the checksum failure in the summary"
else
    fail "Records the checksum failure in the summary"
fi

echo
echo "========== TEST SUMMARY =========="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if (( FAILED > 0 )); then
    exit 1
fi

exit 0
