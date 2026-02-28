<div align="center">

# ⬡ Helix

**What Siri should have been.**

*Built for Mac. Powered by Claude. Persistent memory, system control, voice, and autonomous tasks — all running locally. All yours.*

<br/>

[![macOS](https://img.shields.io/badge/macOS-14%2B-000000?style=flat-square&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Claude Code](https://img.shields.io/badge/Claude_Code-required-CC785C?style=flat-square)](https://claude.ai/claude-code)
[![Node.js](https://img.shields.io/badge/Node.js-20%2B-339933?style=flat-square&logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?style=flat-square&logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![License: ELv2](https://img.shields.io/badge/license-ELv2-5C6BC0?style=flat-square)](LICENSE)

</div>

---

Helix is not a chat app. It's a framework that turns Claude into a personal AI that actually *does things* — opens apps, checks your calendar, remembers things between sessions, runs scheduled tasks while you sleep, and talks back to you out loud if you want it to.

You fork it, configure it, and own it. **Your agent. Your rules. Your Mac.**

---

## What It Does

Helix gives Claude four new superpowers by installing "plugins" (called MCP servers) that connect Claude directly to your Mac:

| Plugin | What it does |
|--------|-------------|
| `helix-mac` | Controls your Mac — opens apps, manages Chrome tabs, reads your Calendar, Reminders, Notes, Music, and Finder |
| `helix-memory` | Remembers things between sessions — no more re-explaining yourself every time you open Claude |
| `helix-agents` | Runs Claude tasks on a schedule automatically, even when you're not at your computer |
| `helix-telegram` | Lets you control your agent from your phone via Telegram |

Plus three things built on top of those:

- **Voice** — Talk to Claude out loud. It listens, responds, and talks back. All runs on your Mac — no cloud, no subscription, no per-word cost.
- **Loops** — Automated tasks that run on a schedule, like a morning briefing, content drafting, or anything you want Claude to do repeatedly without you asking.
- **Identity** — A `CLAUDE.md` file where you define your agent's name, personality, and behavior. It reads this every session — it's how your agent knows who it is and what to do.

## What It's Not

> **Not a web app. Not cross-platform. Not a managed service.**
>
> Helix runs entirely on your Mac. You interact with it through the Terminal (specifically, the `claude` command). If you've never opened Terminal, this might have a learning curve — but the setup guide below walks you through every step.

---

## Why This Won't Get Your Account Banned

There are other frameworks out there that let you run Claude automatically — but some of them do it in ways that violate Anthropic's rules (scraping API keys, using unofficial access methods, etc.). Helix is built differently.

**Here's what makes Helix safe to run long-term:**

- **It uses the official Claude app, period.** Helix runs the same `claude` command you use in Terminal every day — just automated. Anthropic explicitly documents and supports this use case.
- **No other AI services.** Every request goes through your own Claude account. No OpenAI, no Gemini, no third-party proxies. One model, one account, your control.
- **Plugins are the official way to extend Claude.** Anthropic built MCP (the plugin system Helix uses) specifically for this purpose. We're using it exactly as designed.
- **Nothing leaves your Mac.** Memory is a file on your disk. Voice runs on software installed on your machine. Logs stay local. Nothing goes to a server you don't control.

**The bottom line:** Helix can run indefinitely without risking your account because it's built on top of tools Anthropic explicitly supports — not around them.

> **One note:** The framework is safe. What you *automate with it* is your responsibility. If you build a loop that posts to Twitter or Reddit, check those platforms' rules first.

---

## How It Works (Plain English)

Here's the basic picture:

```
You ←→ Claude (in Terminal)
           │
           ├── helix-mac      → your Mac, your apps, your browser
           ├── helix-memory   → remembers things between sessions
           ├── helix-agents   → runs tasks on a schedule
           └── helix-telegram → your phone (optional)
```

When you type `claude` in Terminal, Claude loads all four plugins automatically. It reads your `CLAUDE.md` file to know its name and personality, then it's ready to go.

**Scheduled loops** are separate Claude sessions that wake up on a timer (like "every 30 minutes" or "every morning at 8am"), do one task, then go back to sleep. They log what they did to a file you can check later.

**All sessions share the same memory** — so your phone (via Telegram), your voice session, and your text session all know what's going on with each other.

→ [Full architecture docs](docs/ARCHITECTURE.md)

---

## Setup

### Before you start — what you need

1. **A Mac running macOS 14 or later** (Sonoma or newer — check in  → About This Mac)
2. **Claude Code installed** — this is the `claude` command in Terminal. Get it at [claude.ai/claude-code](https://claude.ai/claude-code) if you don't have it yet. Run `claude --version` to check.
3. **Node.js 20 or later** — this is the engine that runs the Helix plugins. If you're not sure, run `node --version` in Terminal. If you get "command not found", install it:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source ~/.zshrc
nvm install 20
```

---

### Step 1 — Download Helix

Open Terminal and run:

```bash
git clone https://github.com/JonJLevesque/Helix.git ~/Developer/Helix
cd ~/Developer/Helix
cp .env.example .env
```

This downloads Helix into a folder called `Developer/Helix` in your home directory and creates a config file called `.env` from the example.

---

### Step 2 — Fill in your config

Open the `.env` file in any text editor (TextEdit works fine — just make sure it saves as plain text, not rich text). You need to fill in three values. Here's exactly how to find each one:

**`PROJECT_ROOT`** — the full path to the Helix folder you just downloaded. Run this in Terminal, then copy the result:
```bash
echo $HOME/Developer/Helix
```

**`CLAUDE_BIN`** — where the `claude` command lives on your machine. Run this, then copy the result:
```bash
which claude
```
It'll look something like `/Users/yourname/.local/bin/claude`

**`NODE_BIN`** — where Node.js lives. Run this, then copy the result:
```bash
which node
```
It'll look something like `/Users/yourname/.nvm/versions/node/v20.0.0/bin/node`

Your finished `.env` should look something like this:
```bash
PROJECT_ROOT=/Users/janedoe/Developer/Helix
CLAUDE_BIN=/Users/janedoe/.local/bin/claude
NODE_BIN=/Users/janedoe/.nvm/versions/node/v20.15.0/bin/node
```

---

### Step 3 — Install and build

Run this one command — it installs everything and compiles all 4 plugins:

```bash
bash scripts/setup.sh
```

This will take a minute. You'll see a lot of output scrolling by — that's normal. When it finishes you'll see **"Setup complete."**

---

### Step 4 — Confirm the plugins loaded

Run:
```bash
claude mcp list
```

You should see all four listed: `helix-mac`, `helix-memory`, `helix-agents`, `helix-telegram`. If any are missing, the setup script also prints instructions for fixing it manually.

---

### Step 5 — Name your agent

Open `CLAUDE.md` in a text editor. Near the top, find these three placeholders and replace them with whatever you want:

| Find this | Replace with |
|-----------|-------------|
| `{{AGENT_NAME}}` | What you want to call your AI (e.g. "Aria", "Max", "Nova") |
| `{{USER_NAME}}` | Your name |
| `{{NICKNAME}}` | What you want it to call you (e.g. "Boss", "Chief", your first name) |

---

### Step 6 — Start it up

```bash
claude
```

That's it. Your agent starts, loads all 4 plugins, and is ready to go. Try asking it to remember something, check your calendar, or open an app.

<details>
<summary><strong>Something not working?</strong></summary>

**"helix-mac not found" or similar** — run `claude mcp list` to see what's loaded. If a server is missing, check that the path in `.mcp.json` points to a real file. Run `ls mcp-servers/helix-mac/dist/` to confirm it was built.

**Plugin crashes on startup** — run it directly to see the error message:
```bash
node mcp-servers/helix-mac/dist/index.js
```

**Telegram not responding** — verify your bot token is valid:
```bash
curl https://api.telegram.org/bot<TOKEN>/getMe
```

</details>

---

## Voice Mode

Voice mode lets you talk to your agent out loud. It listens, thinks, and talks back — all running locally on your Mac. No cloud service. No per-word charge. No one listening.

**How it works:**
```
Your voice → Whisper (turns speech into text) → Claude (thinks) → Kokoro (speaks the response) → your speakers
```

When you start a session, your agent greets you by voice and listens for 6 seconds. Talk back and it stays in voice mode. Type instead and it silently switches to text. The mode switches automatically — you don't have to do anything.

### Step 1 — Install Whisper (speech-to-text)

Whisper is the software that turns your voice into text. Install it with Python's package manager:

```bash
pip install faster-whisper-server
faster-whisper-server --port 2022 --model base.en
```

To confirm it's running, open a new Terminal tab and run:
```bash
curl http://localhost:2022/health
```
You should see: `{"status":"ok"}`

> **Which model to use:**
> - `tiny.en` — ~50MB download, responds fastest, slightly less accurate
> - `base.en` — ~150MB download, good balance (recommended to start)
> - `small.en` — ~450MB download, most accurate, slightly slower

### Step 2 — Install Kokoro (text-to-speech)

Kokoro is the software that converts Claude's text responses into spoken audio:

```bash
pip install kokoro-onnx
kokoro-server --port 8880
```

To confirm it's running:
```bash
curl http://localhost:8880/health
```
You should see: `{"status":"healthy"}`

### Step 3 — Set your microphone as the audio input

Install a small tool that lets you switch audio inputs from the command line:

```bash
brew install switchaudio-osx
```

Then set your microphone as the input source (replace `"USB PnP Audio Device"` with your mic's name if different — check System Settings → Sound → Input to see the exact name):
```bash
SwitchAudioSource -s "USB PnP Audio Device" -t input
```

### Step 4 — Test everything

```bash
bash services/voice-health-check.sh
```

If all three services show ✓ you're done. If anything shows ✗:

```bash
bash services/voice-auto-recover.sh
```

This script tries to restart whatever's not running. Run the health check again after.

<details>
<summary><strong>Voice cutting out or not detecting silence correctly?</strong></summary>

Edit `~/.voicemode/voicemode.env` (create it if it doesn't exist):

```bash
VOICEMODE_VAD_AGGRESSIVENESS=3    # How strict silence detection is: 0 = permissive, 3 = strict
VOICEMODE_LISTEN_DURATION_MIN=2.0 # Minimum seconds to listen before cutting off
VOICEMODE_SAMPLE_RATE=32000       # Audio sample rate — must match your Whisper server
```

`VAD_AGGRESSIVENESS=3` works well for USB microphones in a room with background noise (fan, AC, computer hum). If it cuts you off too early, try `2`.

**Run voice services at login** so they're ready before you start Claude: create launchd plists for Whisper and Kokoro. See `config/com.helix.template-loop.plist` for the structure — it's the same pattern.

</details>

---

## Loops (Automated Tasks)

A loop is a Claude task that runs automatically on a schedule — like a cron job, but Claude is the one doing the work.

**How it works in plain English:**
1. macOS wakes up the loop on a timer (every 30 minutes, every hour, once a day — whatever you set)
2. A script reads the current state (what's been done, what's queued, what time it is)
3. Claude gets a prompt describing the situation and picks one action to take
4. Claude does the thing (writes a draft, pulls data, checks something, logs a result)
5. The state file gets updated
6. The loop goes back to sleep

The key rule: **one action per run.** Loops are designed to be focused and reliable, not to do everything at once.

**What can loops do?** Anything Claude can do with your tools: draft content, pull data from APIs, check your calendar, write to files, send Telegram messages, call web services, log results. The example in this repo shows a content marketing loop that researches topics and drafts newsletter issues.

**To build your own loop**, start with the scaffold in `services/template-loop/` — it has everything wired up, you just fill in what you want Claude to actually do.

→ [Full loop guide with examples](docs/LOOPS-GUIDE.md)

---

## What's in the Box

```
helix/
├── CLAUDE.md              ← Start here — your agent's name, personality, rules
├── .env.example           ← Config template with every variable explained
├── mcp-servers/
│   ├── helix-mac/         ← The plugin that controls your Mac and Chrome
│   ├── helix-memory/      ← The plugin that remembers things between sessions
│   ├── helix-agents/      ← The plugin that runs and schedules background tasks
│   └── helix-telegram/    ← The plugin that connects your phone via Telegram
├── services/
│   ├── voice-health-check.sh  ← Checks that voice services are running
│   ├── voice-auto-recover.sh  ← Restarts voice services if they crashed
│   ├── noise-gate/            ← Optional audio filtering (advanced)
│   └── template-loop/         ← Starter template for building your own loop
├── agents/
│   ├── schedules/         ← Example scheduled task scripts (morning brief, etc.)
│   └── messages/          ← Where loops leave notes for you or each other
├── config/
│   ├── safety.json        ← Commands Claude is blocked from running
│   ├── example-persona.md ← Template for writing your agent's personality
│   └── com.helix.template-loop.plist  ← Template for scheduling a loop via macOS
├── examples/
│   └── content-loop/      ← A real-world content marketing loop, fully anonymized
├── docs/
│   ├── ARCHITECTURE.md    ← How all the pieces fit together
│   ├── MCP-SERVERS.md     ← Full tool reference for each plugin
│   ├── VOICE-SETUP.md     ← Detailed voice setup guide
│   └── LOOPS-GUIDE.md     ← How to build and schedule your own loops
└── scripts/
    └── setup.sh           ← First-run installer — run this once
```

---

## Requirements

**You need these to run Helix:**
- Mac running macOS 14 (Sonoma) or later — check  → About This Mac
- [Claude Code](https://claude.ai/claude-code) — the `claude` CLI app
- Node.js version 20 or later — run `node --version` to check

**These are optional — only install what you want:**
- Python 3.11+ — only needed for voice (Whisper + Kokoro)
- [faster-whisper-server](https://github.com/fedirz/faster-whisper-server) — speech-to-text for voice mode
- [kokoro-onnx](https://github.com/thewh1teagle/kokoro-onnx) — text-to-speech for voice mode
- A Telegram account — only needed if you want to control your agent from your phone

---

## License

[Elastic License 2.0 (ELv2)](LICENSE) — free to use and modify. Cannot be sold or offered as a managed service without permission.
