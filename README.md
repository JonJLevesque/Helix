# Helix

**A personal AI OS for macOS, powered by Claude.**

Helix is not a chat app. It's an infrastructure layer that gives Claude a home — persistent memory, system control, a voice, a Telegram relay, and the ability to run autonomous background loops while you sleep.

You fork it, configure it, and own it. Your agent. Your rules.

---

## What It Is

Four MCP servers that plug into Claude Code:

| Server | What it does |
|--------|-------------|
| `nova-mac` | macOS control — apps, Chrome, Calendar, Reminders, Notes, Music, Finder |
| `nova-memory` | Persistent JSON memory with keyword search — survives across sessions |
| `nova-agents` | Spawn background Claude agents, schedule them via launchd, coordinate via messages |
| `nova-telegram` | Remote access — control your agent from your phone via Telegram |

Plus:
- **Voice mode** — local Whisper (STT) + Kokoro (TTS), auto health check and recovery
- **Loop framework** — autonomous scheduled tasks via launchd (content posting, briefings, monitoring)
- **Identity layer** — CLAUDE.md defines who your agent is, what it knows, and how it behaves

---

## What It's Not

- Not a cloud service. Runs entirely on your Mac.
- Not cross-platform. macOS only — uses AppleScript, launchd, and CoreAudio.
- Not a UI. It's infrastructure. You interact through Claude Code in your terminal.

---

## Who It's For

macOS developers and power users who want their AI to **do things** — not just answer questions.

If you've ever wished Claude could remember context between sessions, run tasks while you're away, or pick up the phone when you message it from your couch — this is that.

---

## Architecture

```
You ←→ Claude Code (claude CLI)
           │
           ├── nova-mac     → macOS + Chrome
           ├── nova-memory  → Persistent state
           ├── nova-agents  → Background workers + scheduling
           └── nova-telegram → Telegram relay
                    │
              CLAUDE.md (identity + behavior rules)
              .env (secrets + paths)
```

Loops run on launchd schedules, write logs to `agents/logs/`, and surface blockers via `agents/messages/pending-tasks.json`. Voice sessions and Telegram sessions share state through `nova-memory`.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full picture.

---

## Setup

### 1. Clone and configure

```bash
git clone https://github.com/JonJLevesque/Helix.git ~/Developer/Helix
cd ~/Developer/Helix
cp .env.example .env
```

Open `.env` and fill in at minimum:

```bash
PROJECT_ROOT=/Users/yourname/Developer/Helix
CLAUDE_BIN=$(which claude)
NODE_BIN=$(which node)
```

### 2. Build MCP servers

```bash
bash scripts/setup.sh
```

This installs npm packages across all 4 MCP servers and builds TypeScript. Manual alternative:

```bash
for server in mcp-servers/nova-mac mcp-servers/nova-memory mcp-servers/nova-agents mcp-servers/nova-telegram; do
  cd $server && npm install && npm run build && cd ../..
done
```

### 3. Configure MCP servers

`.mcp.json` registers all 4 servers with Claude Code. The setup script patches the paths automatically. To do it manually:

```bash
sed -i '' "s|PROJECT_ROOT|$PROJECT_ROOT|g" .mcp.json
sed -i '' "s|NODE_BIN|$NODE_BIN|g" .mcp.json
sed -i '' "s|CLAUDE_BIN|$CLAUDE_BIN|g" .mcp.json
```

Verify: `claude mcp list` — you should see all four servers.

### 4. Set your identity

Open `CLAUDE.md` and replace the placeholders:

| Placeholder | Replace with |
|-------------|-------------|
| `{{AGENT_NAME}}` | Your agent's name |
| `{{USER_NAME}}` | Your name |
| `{{NICKNAME}}` | What you want to be called |

### 5. Launch

```bash
claude
```

All 4 MCP servers load automatically. Test with `memory_remember`, `app_list`, or `gcal_list`.

### Troubleshooting

**MCP server not loading** — check `claude mcp list` for errors, or run the server manually: `node mcp-servers/nova-mac/dist/index.js`

**Telegram not responding** — verify bot token: `curl https://api.telegram.org/bot<TOKEN>/getMe` and confirm your user ID is in `TELEGRAM_ALLOWED_USER_IDS`

---

## Voice Mode

Local Whisper (STT) + Kokoro (TTS). No cloud. No per-word API cost.

```
You speak → USB Mic → Whisper → transcript → Claude → response text → Kokoro → speakers
```

At session start, Claude runs a health check, then greets you by voice and listens for 6 seconds. If you talk back, it stays in voice mode. If you type, it silently falls back to text.

### 1. Install Whisper

Any OpenAI-compatible `/v1/audio/transcriptions` endpoint works. Easiest:

```bash
pip install faster-whisper-server
faster-whisper-server --port 2022 --model base.en
```

Verify: `curl http://localhost:2022/health` → `{"status":"ok"}`

Model options: `tiny.en` (fastest, ~50MB) · `base.en` (balanced, ~150MB) · `small.en` (more accurate, ~450MB)

### 2. Install Kokoro

```bash
pip install kokoro-onnx
kokoro-server --port 8880
```

Verify: `curl http://localhost:8880/health` → `{"status":"healthy"}`

### 3. Set audio input

```bash
brew install switchaudio-osx
SwitchAudioSource -s "USB PnP Audio Device" -t input
```

### 4. Test

```bash
bash services/voice-health-check.sh
```

All three services should show ✓. If anything fails: `bash services/voice-auto-recover.sh`

### Running at login (recommended)

Create launchd plists for Whisper and Kokoro so they're ready when Claude starts. Basic template:

```xml
<key>Label</key><string>com.helix.whisper</string>
<key>ProgramArguments</key>
<array>
  <string>/path/to/faster-whisper-server</string>
  <string>--port</string><string>2022</string>
  <string>--model</string><string>base.en</string>
</array>
<key>RunAtLoad</key><true/>
<key>KeepAlive</key><true/>
```

### VAD tuning

If Claude cuts you off too early or waits too long after you stop speaking, tune in `~/.voicemode/voicemode.env`:

```bash
VOICEMODE_VAD_AGGRESSIVENESS=3   # 0=permissive, 3=strict
VOICEMODE_LISTEN_DURATION_MIN=2.0
VOICEMODE_SAMPLE_RATE=32000      # must match your Whisper server
```

`vad_aggressiveness=3` with USB direct (no noise gate) correctly ignores ambient hum.

---

## Loops

Loops are scheduled Claude agents that run autonomously via launchd. Every tick: read state, execute one action, update state, exit.

A template loop scaffold is in `services/template-loop/`. A real example (anonymized content marketing loop) is in `examples/content-loop/`.

Loop guide → [docs/LOOPS-GUIDE.md](docs/LOOPS-GUIDE.md)

---

## Directory Structure

```
helix/
├── CLAUDE.md              # Agent identity — customize this first
├── .env.example           # All variables documented
├── mcp-servers/
│   ├── nova-mac/          # macOS system control
│   ├── nova-memory/       # Persistent JSON memory
│   ├── nova-agents/       # Agent spawning + scheduling
│   └── nova-telegram/     # Telegram relay
├── services/
│   ├── voice-health-check.sh
│   ├── voice-auto-recover.sh
│   ├── noise-gate/        # Optional noise reduction
│   └── template-loop/     # Scaffold for your own loop
├── agents/
│   ├── schedules/         # launchd-triggered agent scripts
│   └── messages/          # Inter-agent + pending task queue
├── config/
│   ├── safety.json        # Blocked commands + rate limits
│   ├── example-persona.md # Persona template
│   └── com.helix.template-loop.plist  # launchd template
├── examples/
│   └── content-loop/      # Anonymized real-world loop example
├── docs/
│   ├── ARCHITECTURE.md
│   ├── MCP-SERVERS.md
│   ├── VOICE-SETUP.md
│   └── LOOPS-GUIDE.md
└── scripts/
    └── setup.sh           # First-run installer
```

---

## Requirements

- macOS 14+ (Apple Silicon recommended)
- [Claude Code](https://claude.ai/claude-code) installed (`claude` CLI)
- Node.js 20+ (via nvm recommended)
- Python 3.11+ (for voice services)

Optional:
- [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) or compatible STT server — for voice
- [Kokoro](https://github.com/thewh1teagle/kokoro-onnx) TTS server — for voice
- Telegram account — for remote access

---

## License

[Elastic License 2.0 (ELv2)](LICENSE) — free to use and modify. You may not sell it or offer it as a managed service without permission.
