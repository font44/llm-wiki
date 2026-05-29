#!/usr/bin/env bash
set -u

if [[ "${SKIP_AUTO_LOG:-0}" == "1" ]]; then
  exit 0
fi

REPO="/Users/vijayvar/Documents/workplace/amzn-kb"
LOG_DIR="$REPO/wiki/ai-workspace/log"
STATE_DIR="$REPO/.claude/hooks/state"
mkdir -p "$STATE_DIR"

PAYLOAD="$(cat)"
TRANSCRIPT="$(printf '%s' "$PAYLOAD" | jq -r '.transcript_path // empty')"
SESSION_ID="$(printf '%s' "$PAYLOAD" | jq -r '.session_id // empty')"

[[ -z "$TRANSCRIPT" || ! -f "$TRANSCRIPT" ]] && exit 0

TURNS="$(jq -rs '[.[] | select(.type=="user" or .type=="assistant")] | length' "$TRANSCRIPT" 2>/dev/null || echo 0)"
if (( TURNS < 6 )); then
  exit 0
fi

SESSION_START="$(jq -rs 'first(.[] | .timestamp // empty) // empty' "$TRANSCRIPT" 2>/dev/null)"
if [[ -z "$SESSION_START" ]]; then
  SESSION_START="$(date -u -v-6H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '6 hours ago' +%Y-%m-%dT%H:%M:%SZ)"
fi

TODAY="$(date +%Y-%m-%d)"
TODAY_DIR="$LOG_DIR/$TODAY"

EXISTING_LOGS=""
if [[ -d "$TODAY_DIR" ]]; then
  EXISTING_LOGS="$(find "$TODAY_DIR" -maxdepth 1 -type f -name '*.md' -newermt "$SESSION_START" 2>/dev/null | sort)"
fi

MARKER="$STATE_DIR/$SESSION_ID.done"
[[ -f "$MARKER" ]] && exit 0
touch "$MARKER"

PROMPT_FILE="$STATE_DIR/$SESSION_ID.prompt"
{
  cat <<'PROMPT_HEADER'
You are an auto-logger running after a Claude Code session ended. Your job is to decide whether anything in the just-finished transcript is worth recalling later, and either (a) invoke the `log` skill to write a new entry, (b) merge new substantive content into an existing log file from this session, or (c) exit silently.

## Inputs

PROMPT_HEADER
  printf 'Transcript path: %s\n' "$TRANSCRIPT"
  printf 'Session start (UTC): %s\n' "$SESSION_START"
  printf 'Today: %s\n' "$TODAY"
  printf '\nExisting log files written/modified during this session:\n'
  if [[ -z "$EXISTING_LOGS" ]]; then
    printf '  (none)\n'
  else
    printf '%s\n' "$EXISTING_LOGS" | sed 's|^|  |'
  fi
  cat <<'PROMPT_BODY'

## Procedure

1. Read the transcript. Identify substantive items the future-user would want recalled: stated facts, opinions, decisions, reactions, named people or sources, conclusions of deliberation. Skip pure tool execution, ingests, wiki queries, lints, chitchat, and anything that's just "what Claude did." Apply the log skill's trigger test verbatim: *"is there anything new about the user, their world, or their thinking?"*

2. Read every existing log file listed above in full. Treat their contents as the canonical record of what's already been logged for this session. Do not rephrase, re-summarize, or duplicate anything already there even if you would word it differently.

3. For each substantive item from step 1, check whether it is already represented (semantically, not by string match) in any existing log file. Drop items that are. The remainder is "new content."

4. Branch:
   - **No existing logs + new content is substantive** → invoke the `log` skill to create a new file under wiki/ai-workspace/log/<today>/.
   - **Existing logs + new content is substantive** → edit the most topically relevant existing file in place. Append to it, refine the title if the scope shifted, and bump `updated:` to the current local time. Only start a new file if the new content is a genuinely unrelated thread.
   - **Existing logs + nothing new** → exit silently. Print "no-op: existing logs already cover this session" and stop.
   - **Not substantive at all** → exit silently. Print "no-op: nothing substantive to log" and stop.

5. Be conservative. False negatives (missing a log) are cheaper than false positives (duplicate or noisy entries). If the call is close, prefer no-op.

Do not ask the user anything. Do not print long summaries. One line of output at the end stating what you did, matching the log skill's convention.
PROMPT_BODY
} > "$PROMPT_FILE"

LOG_OUT="$STATE_DIR/$SESSION_ID.out"
SKIP_AUTO_LOG=1 nohup claude -p \
  --add-dir "$REPO" \
  --permission-mode bypassPermissions \
  < "$PROMPT_FILE" \
  > "$LOG_OUT" 2>&1 &

disown 2>/dev/null || true
exit 0
