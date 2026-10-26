#!/usr/bin/env bash
# =============================================================================
# CMCKO — JMeter Load Generator Runner
# Generates external traffic to test L4 and L7 observability across clusters
#
# USAGE:
#   ./jmeter/run-jmeter.sh [TARGET_HOST] [PORT] [THREADS] [DURATION_SECS]
#
# EXAMPLES:
#   # Test Mac cluster locally:
#   ./jmeter/run-jmeter.sh localhost 30080 15 180
#
#   # Test System 1 (Mac) over LAN:
#   ./jmeter/run-jmeter.sh 192.168.1.50 30080 20 300
#
#   # Test System 2 (WSL2) over LAN:
#   ./jmeter/run-jmeter.sh 192.168.1.60 30080 20 300
# =============================================================================

TARGET_HOST="${1:-localhost}"
TARGET_PORT="${2:-30080}"
THREADS="${3:-15}"
DURATION="${4:-300}"
RAMPUP="${5:-5}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JMX_FILE="$SCRIPT_DIR/cmcko-traffic-test.jmx"
LOG_DIR="$SCRIPT_DIR/results"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_FILE="$LOG_DIR/run_${TIMESTAMP}.jtl"

echo "═══════════════════════════════════════════════════════════════════"
echo "  CMCKO External Traffic Generator (Apache JMeter)"
echo "═══════════════════════════════════════════════════════════════════"
echo "  Target Host:       $TARGET_HOST"
echo "  Target Port:       $TARGET_PORT"
echo "  Virtual Users:     $THREADS threads"
echo "  Ramp-Up:           $RAMPUP seconds"
echo "  Duration:          $DURATION seconds"
echo "  Test Plan:         $JMX_FILE"
echo "  Results:           $RESULT_FILE"
echo "═══════════════════════════════════════════════════════════════════"

if command -v jmeter &>/dev/null; then
  jmeter -n \
    -t "$JMX_FILE" \
    -Jtarget.host="$TARGET_HOST" \
    -Jtarget.port="$TARGET_PORT" \
    -Jthreads="$THREADS" \
    -Jduration="$DURATION" \
    -Jrampup="$RAMPUP" \
    -l "$RESULT_FILE"
else
  echo ""
  echo "⚠️  Apache JMeter CLI not found in PATH."
  echo "You can run this test plan using Docker without installing JMeter locally:"
  echo ""
  echo "docker run --rm -i -v \"$SCRIPT_DIR\":/jmeter justb4/jmeter:latest \\"
  echo "  -n -t /jmeter/cmcko-traffic-test.jmx \\"
  echo "  -Jtarget.host=\"$TARGET_HOST\" \\"
  echo "  -Jtarget.port=\"$TARGET_PORT\" \\"
  echo "  -Jthreads=\"$THREADS\" \\"
  echo "  -Jduration=\"$DURATION\""
fi
