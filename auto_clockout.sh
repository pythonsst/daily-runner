#!/bin/bash

# === Auto Web Clock-Out for Keka ===
LOG_FILE="/tmp/auto_clockout.log"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# ✅ Load environment variables
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  echo "❌ [$TIMESTAMP] .env file not found" >> "$LOG_FILE"
  exit 1
fi

echo "🕙 [$TIMESTAMP] Clock-Out script initiated" >> "$LOG_FILE"

# ✅ Prepare Clock-Out request body
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

# ✅ Clock-Out API call
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "https://validus.keka.com/k/attendance/api/mytime/attendance/webclockin" \
  -H "Authorization: Bearer $BEARER_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Referer: https://validus.keka.com/" \
  -H "Origin: https://validus.keka.com" \
  -d "$REQUEST_BODY")

BODY=$(echo "$RESPONSE" | head -n 1)
STATUS=$(echo "$RESPONSE" | tail -n 1)

echo "🔁 Clock-Out Request Body: $REQUEST_BODY" >> "$LOG_FILE"
echo "📦 Clock-Out Response Body: $BODY" >> "$LOG_FILE"
echo "📡 HTTP Status: $STATUS" >> "$LOG_FILE"

if [ "$STATUS" == "200" ]; then
  echo "✅ [$TIMESTAMP] Clock-Out successful" >> "$LOG_FILE"
else
  echo "❌ [$TIMESTAMP] Clock-Out failed (Status: $STATUS)" >> "$LOG_FILE"
fi
