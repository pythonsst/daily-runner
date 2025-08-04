# 🧠 Auto-Logout on macOS (Mon–Fri at 10:00 PM) – Rocket-Level Automation

## ✅ Objective

Automatically logout every weekday (Monday to Friday) at exactly 10:00 PM, using:

* macOS LaunchAgent
* `pmset` to wake the system
* Custom Bash script to logout via Keka WebClockOut API

---

## 🔧 What We Did – Step by Step

### ✅ 1. Create Auto Clock-Out Script

**Path**: `~/scripts/auto_clockout.sh`

```bash
#!/bin/bash

LOG_FILE="/tmp/auto_clockout.log"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

SCRIPT_DIR="$(cd \"$(dirname \"${BASH_SOURCE[0]}\")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  echo "❌ [$TIMESTAMP] .env file not found" >> "$LOG_FILE"
  exit 1
fi

echo "⏱️ [$TIMESTAMP] Clock-Out Initiated" >> "$LOG_FILE"

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

CLOCKOUT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "https://validus.keka.com/k/attendance/api/mytime/attendance/webclockin" \
  -H "Authorization: Bearer $BEARER_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Referer: https://validus.keka.com/" \
  -H "Origin: https://validus.keka.com" \
  -d "$REQUEST_BODY")

CLOCKOUT_BODY=$(echo "$CLOCKOUT_RESPONSE" | head -n 1)
CLOCKOUT_STATUS=$(echo "$CLOCKOUT_RESPONSE" | tail -n 1)

echo "📦 Clock-Out Response Body: $CLOCKOUT_BODY" >> "$LOG_FILE"
echo "📡 Clock-Out HTTP Status: $CLOCKOUT_STATUS" >> "$LOG_FILE"

if [ "$CLOCKOUT_STATUS" == "200" ]; then
  echo "✅ [$TIMESTAMP] Clock-Out successful" >> "$LOG_FILE"
else
  echo "❌ [$TIMESTAMP] Clock-Out failed (Status: $CLOCKOUT_STATUS)" >> "$LOG_FILE"
fi
```

Make it executable:

```bash
chmod +x ~/scripts/auto_clockout.sh
```

---

### ✅ 2. Create `.env` File

**Path**: `~/scripts/.env`

```ini
BEARER_TOKEN=your_actual_keka_token_here
```

---

### ✅ 3. Create LaunchAgent `.plist`

**Path**: `~/Library/LaunchAgents/com.validus.clockout.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.validus.clockout</string>

    <key>ProgramArguments</key>
    <array>
      <string>/Users/shiv/scripts/auto_clockout.sh</string>
    </array>

    <key>StartCalendarInterval</key>
    <array>
      <dict><key>Hour</key><integer>22</integer><key>Minute</key><integer>0</integer><key>Weekday</key><integer>1</integer></dict>
      <dict><key>Hour</key><integer>22</integer><key>Minute</key><integer>0</integer><key>Weekday</key><integer>2</integer></dict>
      <dict><key>Hour</key><integer>22</integer><key>Minute</key><integer>0</integer><key>Weekday</key><integer>3</integer></dict>
      <dict><key>Hour</key><integer>22</integer><key>Minute</key><integer>0</integer><key>Weekday</key><integer>4</integer></dict>
      <dict><key>Hour</key><integer>22</integer><key>Minute</key><integer>0</integer><key>Weekday</key><integer>5</integer></dict>
    </array>

    <key>StandardOutPath</key>
    <string>/tmp/auto_clockout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/auto_clockout.log</string>

    <key>RunAtLoad</key>
    <true/>
  </dict>
</plist>
```

---

### ✅ 4. Load the LaunchAgent

```bash
launchctl unload ~/Library/LaunchAgents/com.validus.clockout.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/com.validus.clockout.plist
```

Verify:

```bash
launchctl list | grep com.validus.clockout
```

---

### ✅ 5. Schedule Wake-Up at 10:00 PM (Weekdays)

```bash
sudo pmset repeat wakepoweron MTWRF 22:00:00
```

Verify:

```bash
pmset -g sched
```

---

## 🧪 Testing

Manually trigger:

```bash
launchctl start com.validus.clockout
```

View logs:

```bash
tail -f /tmp/auto_clockout.log
```

---

## 🧨 Result

At exactly **10:00 PM (Mon–Fri)** your Mac will:

* ✅ Wake up
* ✅ Trigger LaunchAgent
* ✅ Hit Keka WebClockOut API
* ✅ Log the response
* ✅ Leave Mac awake (no sleep)

---

## 💡 Optional Add-ons

* Send Slack/email notification on success
* Add retry mechanism for failed requests
* Refresh bearer token automatically

---

**Want this as PDF or GitHub-ready `.md`?** Let me know!
