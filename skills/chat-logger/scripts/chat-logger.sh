#!/usr/bin/env bash
# Chat Logger — Bash (Linux/Mac)
# Reads stop hook stdin, extracts turn data from transcript, appends to chat-log.md

set -euo pipefail

INPUT=$(cat)

# Guard: if already in correction cycle, exit
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0
fi

CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')
LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // ""')

if [ -z "$CWD" ] || [ -z "$TRANSCRIPT" ]; then
  exit 0
fi

LOGFILE="$CWD/chat-log.md"

# Extract user message from last 20 lines of transcript
USER_MSG=""
TOOL_NAMES=""

if [ -f "$TRANSCRIPT" ]; then
  LINES=$(tail -2000 "$TRANSCRIPT")
  USER_MSG=$(echo "$LINES" | while IFS= read -r line; do
    type=$(echo "$line" | jq -r '.type // ""' 2>/dev/null)
    if [ "$type" = "user" ]; then
      text=$(echo "$line" | jq -r '.message.content // [] | if type == "array" then [.[] | select(.type == "text") | .text] | join("") else "" end' 2>/dev/null)
      if [ -n "$text" ]; then
        echo "$text"
        break
      fi
    fi
  done | tail -1)

  # Extract tool names from assistant blocks (already deduplicated and joined)
  TOOL_NAMES=$(echo "$LINES" | while IFS= read -r line; do
    type=$(echo "$line" | jq -r '.type // ""' 2>/dev/null)
    if [ "$type" = "assistant" ]; then
      echo "$line" | jq -r '.message.content // [] | if type == "array" then [.[] | select(.type == "tool_use") | .name] | unique | join(", ") else "" end' 2>/dev/null
    fi
  done | grep -v '^$' | tail -1)
fi

if [ -z "$USER_MSG" ]; then
  exit 0
fi

# Timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

# Build markdown block
MD=$'\n'"## $TIMESTAMP"$'\n\n'
MD+="**User:**"$'\n'"$USER_MSG"$'\n\n'
MD+="**Claude:**"$'\n'"$LAST_MSG"$'\n'

if [ -n "$TOOL_NAMES" ]; then
  MD+=$'\n'"> Tools: $TOOL_NAMES"$'\n'
fi

MD+=$'\n'"---"$'\n'

# Write to log file
if [ ! -f "$LOGFILE" ]; then
  PROJECT_NAME=$(basename "$CWD")
  printf '%s\n\n' "# Chat Log — $PROJECT_NAME" > "$LOGFILE"
fi

printf '%s' "$MD" >> "$LOGFILE"

exit 0
