# Example: Content Loop

A real-world content marketing loop, stripped to the reusable patterns.

## What It Demonstrates

- **Time-of-day mode switching** — ACTIVE hours (8am–10pm) for distribution, BUILD hours (off-peak) for research and drafting
- **State file management** — queue, daily caps, last action tracking, all in a single markdown file the agent reads and rewrites each tick
- **One-action-per-tick discipline** — the loop picks the single highest-priority item and does only that
- **Revenue tracking** — optional Gumroad API integration to surface sales data each tick
- **Newsletter publishing** — Beehiiv API integration, always publishing as `draft` for human review before send
- **Engagement log** — every distribution action appended to `memory/engagement-log.json`
- **Escalation pattern** — blockers that need human input go to `agents/messages/pending-tasks.json`, never block the tick

## What You Plug In

The **DISTRIBUTION** section of `prompt-template.sh` is intentionally left as a scaffold. Fill it in with however you actually publish content — your own platform API, a CMS, email, wherever. The loop architecture works the same regardless.

---

## Files

| File | Purpose |
|------|---------|
| `prompt-template.sh` | Loop prompt — reads state, defines rules, runs the agent |
| `persona.md` | The voice your content uses — create this yourself |
| `state.md` | Current queue, daily counts, last actions — initialize this |
| `run.sh` | Entry point (copy of `services/template-loop/run.sh`) |

---

## Setup

### 1. Configure `.env`

```bash
# Optional — remove if not using
GUMROAD_ACCESS_TOKEN=your_token
BEEHIIV_API_KEY=your_key
BEEHIIV_PUB_ID=your_pub_id
BUSINESS_URL=https://yourbusiness.com
NEWSLETTER_URL=https://yournewsletter.beehiiv.com/subscribe
```

### 2. Write your persona

Create `examples/content-loop/persona.md`. Define the voice, expertise, and tone your content uses. See `config/example-persona.md` for a template.

### 3. Initialize state

Create `examples/content-loop/state.md`:

```markdown
# Content Loop State

## Loop State
- Last run: [never]
- Last action: [none]
- Last result: [none]
- Mode: BUILD
- Published today: 0 (resets midnight)

## Queue
- [ ] Research: find top questions in [your niche] this week
- [ ] Draft newsletter issue #1 — topic: [your topic]

## Backlog
- Expand to [new channel] once newsletter hits 100 subscribers
```

### 4. Load into launchd

```bash
cp config/com.helix.template-loop.plist ~/Library/LaunchAgents/com.helix.content-loop.plist
# Edit: change template-loop → content-loop, update paths, set StartInterval
launchctl load ~/Library/LaunchAgents/com.helix.content-loop.plist
```

---

## Platform Compliance Note

When building loops that publish content or interact with online platforms, check those platforms' terms of service and API policies. Use official APIs where available, respect rate limits, and disclose AI involvement where required. The loop framework is neutral — what you do with it is your responsibility.

---

## Full Loop Guide

→ [docs/LOOPS-GUIDE.md](../../docs/LOOPS-GUIDE.md)
