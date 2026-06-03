# Chat Logger — PowerShell (Windows)
# Reads stop hook stdin, extracts turn data from transcript, appends to chat-log.md

$ErrorActionPreference = "SilentlyContinue"

# Read hook JSON from stdin
$stdinRaw = [Console]::In.ReadToEnd().TrimStart([char]0xFEFF)
if (-not $stdinRaw) { exit 0 }

try {
    $hookData = $stdinRaw | ConvertFrom-Json
} catch {
    Write-Warning "chat-logger: failed to parse hook JSON"
    exit 0
}

# Guard against infinite loop: if already in stop-hook correction cycle, exit
if ($hookData.stop_hook_active -eq $true) { exit 0 }

$cwd = $hookData.cwd
$transcriptPath = $hookData.transcript_path
$sessionId = $hookData.session_id

if (-not $cwd -or -not $transcriptPath) { exit 0 }

$logFile = Join-Path $cwd "chat-log.md"

# Read transcript to get user message and tool calls
# Transcript uses: type (user/assistant), message.content (array of blocks)
$userMessage = ""
$toolNames = @()

if (Test-Path $transcriptPath) {
    $lines = Get-Content -Path $transcriptPath -Encoding UTF8 -Tail 2000
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        try {
            $entry = $lines[$i] | ConvertFrom-Json
            if (-not $entry.message -or -not $entry.message.content) { continue }
            $content = $entry.message.content
            if (-not ($content -is [array])) { continue }

            # Extract user text message (last one before current assistant turn)
            if ($entry.type -eq "user" -and -not $userMessage) {
                foreach ($block in $content) {
                    if ($block.type -eq "text" -and $block.text) {
                        $userMessage = $block.text
                    }
                }
            }

            # Collect tool call names from assistant turns
            if ($entry.type -eq "assistant") {
                foreach ($block in $content) {
                    if ($block.type -eq "tool_use" -and $block.name) {
                        $toolNames += $block.name
                    }
                }
            }
        } catch {}
    }
}

if (-not $userMessage) { exit 0 }

# Get Claude's last response text
$claudeResponse = $hookData.last_assistant_message
if (-not $claudeResponse) { $claudeResponse = "" }

# Get timestamp
$timeStr = (Get-Date).ToString("yyyy-MM-dd HH:mm")

# Build markdown
$md = @"

## $timeStr

**User:**
$userMessage

**Claude:**
$claudeResponse

"@

if ($toolNames.Count -gt 0) {
    $toolList = ($toolNames | Select-Object -Unique) -join ", "
    $md += @"

> Tools: $toolList

"@
}

$md += @"

---

"@

# Write to log file
try {
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    if (-not (Test-Path $logFile)) {
        $projectName = Split-Path $cwd -Leaf
        $header = "# Chat Log -- $projectName`n`n"
        [System.IO.File]::WriteAllText($logFile, $header, $utf8NoBom)
    }
    [System.IO.File]::AppendAllText($logFile, $md, $utf8NoBom)
} catch {
    Write-Warning "chat-logger: failed to write log: $_"
}

exit 0
