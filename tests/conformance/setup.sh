#!/usr/bin/env bash
set -euo pipefail

echo "Building Aether..."
cd aether-ref
cargo build --release

echo "Starting Aether server..."
./target/release/aether serve \
  --bind 127.0.0.1:8080 \
  --audit-key-hex 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef &
AETHER_PID=$!
echo "Aether PID: $AETHER_PID"

# Wait for health endpoint
for i in $(seq 1 30); do
  if curl -sf http://127.0.0.1:8080/api/v1/health > /dev/null 2>&1; then
    echo "Aether is ready."
    break
  fi
  sleep 1
done

# Load sample policy
echo "Loading sample policy..."
curl -sf -X POST http://127.0.0.1:8080/api/v1/policies \
  -H "Content-Type: application/yaml" \
  --data-binary @deploy/sample-policy.yaml

# Ingest baseline telemetry
echo "Ingesting telemetry..."
curl -sf -X POST http://127.0.0.1:8080/api/v1/telemetry \
  -H "Content-Type: application/json" \
  -d '{"link_id": "leo_01", "availability": "up", "timestamp": "2026-01-01T00:00:00Z", "source_id": "test", "latency_ms": 40}'

curl -sf -X POST http://127.0.0.1:8080/api/v1/telemetry \
  -H "Content-Type: application/json" \
  -d '{"link_id": "lte_01", "availability": "up", "timestamp": "2026-01-01T00:00:00Z", "source_id": "test", "latency_ms": 15}'

echo "Setup complete. Run: hurl --test tests/conformance/*.hurl"
echo "Cleanup: kill $AETHER_PID"
export AETHER_PID
