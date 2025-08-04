#!/bin/bash

# === Auto Web Clock-Out for Keka ===
LOG_FILE="/tmp/auto_clockout.log"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# ✅ Load .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  echo "❌ [$TIMESTAMP] .env file not found" >> "$LOG_FILE"
  exit 1
fi

echo "⏱️ [$TIMESTAMP] Web Clock-Out Initiated" >> "$LOG_FILE"

# ✅ Get current public IP
CURRENT_IP=$(curl -s ifconfig.me)
echo "🌐 Public IP: $CURRENT_IP" >> "$LOG_FILE"

# ✅ Prepare Request Body
REQUEST_BODY=$(cat <<EOF
{
  "manualClockinType": 1,
  "note": "",
  "punchStatus": 1,
  "isAdjusted": false,
  "isDeleted": false,
  "manualLatitude": "17.4470148",
  "manualLongitude": "78.3613997",
  "manualLocation": "Chhota Anjaiah Nagar, Hyderabad"
}
EOF
)

# ✅ Make API Call
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "https://validus.keka.com/k/attendance/api/mytime/attendance/webclockin" \
  -H "Authorization: Bearer $BEARER_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Referer: https://validus.keka.com/" \
  -H "Origin: https://validus.keka.com" \
  -d "$REQUEST_BODY")

# ✅ Parse Response
BODY=$(echo "$RESPONSE" | head -n 1)
STATUS=$(echo "$RESPONSE" | tail -n 1)

echo "🔁 Request Body: $REQUEST_BODY" >> "$LOG_FILE"
echo "📦 Response Body: $BODY" >> "$LOG_FILE"
echo "📡 HTTP Status: $STATUS" >> "$LOG_FILE"

# ✅ Final Outcome
if [ "$STATUS" == "200" ]; then
  echo "✅ [$TIMESTAMP] Clock-Out successful" >> "$LOG_FILE"
else
  echo "❌ [$TIMESTAMP] Clock-Out failed (Status: $STATUS)" >> "$LOG_FILE"
fi
