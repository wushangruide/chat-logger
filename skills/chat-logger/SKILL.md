---
name: chat-logger
description: Use when the user wants to automatically log Claude Code conversations to a local markdown file, or install/configure chat history logging
---

# Chat Logger

## Overview

Automatically log every conversation turn (user message + Claude response + tool call summary) to a per-project `chat-log.md` file. Powered by a stop hook — install once, works forever.

## Installation

To install, tell Claude: "Install the chat-logger skill." Claude will:

1. Detect your OS (Windows = PowerShell, Linux/Mac = Bash)
2. Copy the appropriate script to `.claude/scripts/chat-logger.{ps1,sh}`
3. Register a stop hook in `.claude/settings.local.json`
4. Initialize `chat-log.md` if it doesn't exist

After installation, the logger works automatically — no further action needed.

## Hook Configuration

The stop hook is registered as:

```json
{
  "hooks": {
    "stop": ".claude/scripts/chat-logger.sh"
  }
}
```

On Windows, the command is `powershell -ExecutionPolicy Bypass -File ".claude/scripts/chat-logger.ps1"`.

## Log Format

```markdown
# Chat Log — project-name

## 2026-06-03 14:30

**用户：**
<user message>

**Claude：**
<claude response text>

> 🔧 工具调用：Read, Edit, Bash

---
```

Each turn gets a timestamped heading. Tool calls are summarized in a blockquote (names only, no arguments). File is UTF-8 encoded.

## Uninstall

To remove: delete the stop hook from `.claude/settings.local.json` and remove `.claude/scripts/chat-logger.{ps1,sh}`. The `chat-log.md` file is not deleted.

## Common Issues

- **Log file not updating**: Check that the stop hook is registered correctly in `settings.local.json`. Verify the script exists at `.claude/scripts/`.
- **"jq not found" (Linux/Mac)**: Run `sudo apt install jq` (Ubuntu) or `brew install jq` (Mac).
- **PowerShell execution policy (Windows)**: The hook uses `-ExecutionPolicy Bypass` to avoid this.
- **File size**: The log appends forever. Rename `chat-log.md` manually when you want to archive.
