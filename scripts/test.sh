#!/bin/bash
WEBHOOK_URL="http://localhost:5678/webhook/email-triage"

echo "--- Testing URGENT ---"
curl -s -X POST $WEBHOOK_URL \
  -H "Content-Type: application/json" \
  -d @sample-payloads/urgent.json | jq

echo ""
echo "--- Testing ACTIONABLE ---"
curl -s -X POST $WEBHOOK_URL \
  -H "Content-Type: application/json" \
  -d @sample-payloads/actionable.json | jq

echo ""
echo "--- Testing FYI ---"
curl -s -X POST $WEBHOOK_URL \
  -H "Content-Type: application/json" \
  -d @sample-payloads/fyi.json | jq
  