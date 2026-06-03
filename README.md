# Chat Logger

Automatically log Claude Code conversations to a per-project `chat-log.md` file via stop hooks. Install once, works forever.

## How It Works

After each Claude response, a stop hook fires and pipes session data (transcript path, assistant message, cwd) to a script. The script reads the session transcript JSONL, extracts the user message and tool calls, and appends a formatted markdown entry to `chat-log.md` in the project root.

## Installation

### Via Plugin Marketplace (recommended)

1. Add the marketplace to your Claude Code config:

```json
{
  "extraKnownMarketplaces": {
    "chat-logger": {
      "source": {
        "source": "github",
        "repo": "wushangruide/chat-logger"
      }
    }
  }
}
```

2. Install the plugin:

```
/plugin install chat-logger@chat-logger
```

3. Tell Claude: "Install the chat-logger skill" — it will copy the right script for your OS and register the stop hook.

### Manual Install

1. Copy the script for your OS to `.claude/scripts/`:
   - Windows: `skills/chat-logger/scripts/chat-logger.ps1` → `.claude/scripts/chat-logger.ps1`
   - Linux/Mac: `skills/chat-logger/scripts/chat-logger.sh` → `.claude/scripts/chat-logger.sh`

2. Register the stop hook in `.claude/settings.local.json`:

**Windows:**
```json
{
  "hooks": {
    "stop": "powershell -ExecutionPolicy Bypass -File \".claude/scripts/chat-logger.ps1\""
  }
}
```

**Linux/Mac:**
```json
{
  "hooks": {
    "stop": ".claude/scripts/chat-logger.sh"
  }
}
```

## Log Format

```markdown
# Chat Log — project-name

## 2026-06-03 14:30

**User:**
<user message>

**Claude:**
<claude response text>

> Tools: Read, Edit, Bash

---
```

UTF-8 encoded. Tool calls show names only (no arguments).

## Requirements

- **Linux/Mac**: `jq` must be installed (`apt install jq` / `brew install jq`)
- **Windows**: PowerShell 5.1+ (built-in)

## Uninstall

Delete the stop hook from `.claude/settings.local.json` and remove `.claude/scripts/chat-logger.{ps1,sh}`. The `chat-log.md` file is not deleted.

## License

MIT
