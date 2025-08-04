#!/bin/bash

# === Smart Web Clock In/Out for Keka ===
LOG_FILE="/tmp/auto_clock.log"
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

echo "📆 [$TIMESTAMP] Checking clock-in status..." >> "$LOG_FILE"

# ✅ Get current attendance status
ATTENDANCE_STATUS=$(curl -s -X GET "https://validus.keka.com/k/attendance/api/mytime/today" \
  -H "Authorization: Bearer $BEARER_TOKEN" \
  -H "Referer: https://validus.keka.com/" \
  -H "Origin: https://validus.keka.com" \
  -H "Content-Type: application/json")

IS_CLOCKED_IN=$(echo "$ATTENDANCE_STATUS" | grep -o '"hasClockIn":true')

# ✅ Determine action
if [[ "$IS_CLOCKED_IN" == *"true"* ]]; then
  echo "🟡 Already clocked in. Proceeding to clock out." >> "$LOG_FILE"
  PUNCH_STATUS=1
  ACTION="Clock-Out"
else
  echo "🟢 Not clocked in. Proceeding to clock in." >> "$LOG_FILE"
  PUNCH_STATUS=0
  ACTION="Clock-In"
fi

# ✅ Prepare Request Body
REQUEST_BODY=$(cat <<EOF
{
  "manualClockinType": 1,
  "note": "",
  "punchStatus": $PUNCH_STATUS,
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

echo "📝 Action: $ACTION" >> "$LOG_FILE"
echo "🔁 Request Body: $REQUEST_BODY" >> "$LOG_FILE"
echo "📦 Response Body: $BODY" >> "$LOG_FILE"
echo "📡 HTTP Status: $STATUS" >> "$LOG_FILE"

if [ "$STATUS" == "200" ]; then
  echo "✅ [$TIMESTAMP] $ACTION successful" >> "$LOG_FILE"
else
  echo "❌ [$TIMESTAMP] $ACTION failed (Status: $STATUS)" >> "$LOG_FILE"
fi
