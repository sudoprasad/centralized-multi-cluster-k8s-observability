#!/usr/bin/env bash
# =============================================================================
# CMCKO — JMeter Load Generator Runner
# Real-World Flash Spike Simulation (ERP Result Declaration / Flash Sale)
#
# USAGE:
#   ./jmeter/run-jmeter.sh [TARGET_HOST] [PORT] [THREADS] [DURATION_SECS] [RAMPUP_SECS] [THINK_TIME_MS]
#
# EXAMPLES:
#   # Real-World Flash Spike (35 users, 15s surge, 200ms think time):
#   ./jmeter/run-jmeter.sh 100.110.71.94 30080 35 300 15 200
#
#   # Massive Flash Spike (50 users, 15s surge, 150ms think time):
#   ./jmeter/run-jmeter.sh 100.110.71.94 30080 50 300 15 150
#
#   # Local Mac cluster:
#   ./jmeter/run-jmeter.sh localhost 30080
# =============================================================================

TARGET_HOST="${1:-localhost}"
TARGET_PORT="${2:-30080}"
THREADS="${3:-35}"
DURATION="${4:-300}"
RAMPUP="${5:-15}"
THINK_TIME="${6:-200}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JMX_FILE="$SCRIPT_DIR/cmcko-traffic-test.jmx"
LOG_DIR="$SCRIPT_DIR/results"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_FILE="$LOG_DIR/run_${TIMESTAMP}.jtl"

MODE_DESC="Real-World Flash Spike (Human think time: ${THINK_TIME}ms ± 50ms)"

echo "═══════════════════════════════════════════════════════════════════"
echo "  CMCKO Traffic Generator: Real-World Flash Spike Scenario"
echo "  (Simulates ERP Result Declaration / E-Commerce Flash Sale)"
echo "═══════════════════════════════════════════════════════════════════"
echo "  Target Host:       $TARGET_HOST"
echo "  Target Port:       $TARGET_PORT"
echo "  Virtual Users:     $THREADS threads"
echo "  Ramp-Up:           $RAMPUP seconds"
echo "  Duration:          $DURATION seconds"
echo "  Think Time:        ${THINK_TIME} ms ($MODE_DESC)"
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
    -Jthinktime="$THINK_TIME" \
    -l "$RESULT_FILE"
elif command -v docker &>/dev/null; then
  DOCKER_TARGET="$TARGET_HOST"
  if [ "$TARGET_HOST" = "localhost" ] || [ "$TARGET_HOST" = "127.0.0.1" ]; then
    DOCKER_TARGET="host.docker.internal"
  fi
  echo "ℹ️  JMeter CLI not found locally. Running via Docker (justb4/jmeter:latest)..."
  docker run --rm -i \
    -v "$SCRIPT_DIR":/jmeter \
    justb4/jmeter:latest \
    -n -t /jmeter/cmcko-traffic-test.jmx \
    -Jtarget.host="$DOCKER_TARGET" \
    -Jtarget.port="$TARGET_PORT" \
    -Jthreads="$THREADS" \
    -Jduration="$DURATION" \
    -Jrampup="$RAMPUP" \
    -Jthinktime="$THINK_TIME" \
    -l "/jmeter/results/run_${TIMESTAMP}.jtl"
else
  echo ""
  echo "⚠️  Neither Apache JMeter CLI nor Docker found."
  echo "Please install JMeter ('brew install jmeter') or ensure Docker/OrbStack is running."
fi
