#!/bin/bash
# Helix Example: Content Loop — Prompt Template
# A real-world content marketing loop, stripped to the reusable patterns:
#   - Time-of-day mode switching (ACTIVE vs BUILD)
#   - State file management (queue, cooldowns, daily caps)
#   - Rate limiting and one-action-per-tick discipline
#   - Revenue tracking via Gumroad API
#   - Newsletter drafting and publishing via Beehiiv
#
# What to plug in yourself:
#   - The DISTRIBUTION section: where/how you publish content (your platform, your API)
#   - Your persona file
#   - Your state file with your own queue items
#
# Required .env variables:
#   GUMROAD_ACCESS_TOKEN — (optional) for revenue tracking
#   BEEHIIV_API_KEY      — (optional) for newsletter publishing
#   BEEHIIV_PUB_ID       — (optional) Beehiiv publication ID
#   BUSINESS_URL         — your main website URL
#   GUMROAD_PRODUCT_URL  — your Gumroad store link
#   NEWSLETTER_URL       — your newsletter subscribe URL

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
STATE_FILE="$PROJECT_ROOT/examples/content-loop/state.md"
PERSONA_FILE="$PROJECT_ROOT/examples/content-loop/persona.md"
NOW="$(date '+%A, %B %d, %Y at %I:%M %p %Z')"

# Source .env
if [ -f "$PROJECT_ROOT/.env" ]; then set -a; source "$PROJECT_ROOT/.env"; set +a; fi

# ── Time-of-day mode ────────────────────────────────────────────────────────
# ACTIVE: distribution hours — publish, engage, distribute
# BUILD:  off-hours — research, draft, plan
HOUR=$(TZ='America/Los_Angeles' date '+%-H')
if [ "$HOUR" -ge 8 ] && [ "$HOUR" -lt 22 ]; then
  TIME_MODE="ACTIVE"
else
  TIME_MODE="BUILD"
fi
CURRENT_TIME=$(TZ='America/Los_Angeles' date '+%I:%M %p %Z')

STATE_CONTENT="$(cat "$STATE_FILE" 2>/dev/null || echo '[state file not found — create examples/content-loop/state.md]')"
PERSONA_CONTENT="$(cat "$PERSONA_FILE" 2>/dev/null || echo '[persona file not found — create examples/content-loop/persona.md]')"

# ── Live revenue from Gumroad (optional) ────────────────────────────────────
REVENUE_SUMMARY="[Gumroad tracking disabled — set GUMROAD_ACCESS_TOKEN to enable]"
if [ -n "${GUMROAD_ACCESS_TOKEN:-}" ]; then
  _RAW=$(curl -s "https://api.gumroad.com/v2/products" \
    -H "Authorization: Bearer $GUMROAD_ACCESS_TOKEN" 2>/dev/null)
  REVENUE_SUMMARY=$(echo "$_RAW" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    products = d.get('products', [])
    total_sales = sum(p.get('sales_count', 0) for p in products)
    total_cents = sum(p.get('sales_usd_cents', 0) for p in products)
    lines = []
    for p in products:
        lines.append(f'  {p[\"name\"][:60]}: {p.get(\"sales_count\",0)} sales / \${p.get(\"sales_usd_cents\",0)/100:.2f}')
    lines.append(f'  TOTAL: {total_sales} sales / \${total_cents/100:.2f}')
    print('\n'.join(lines))
except Exception as e:
    print(f'[error: {e}]')
" 2>/dev/null || echo "[revenue fetch failed]")
fi

read -r -d '' LOOP_PROMPT << PROMPT_EOF || true
Today is $NOW.
Current time: $CURRENT_TIME
Mode: $TIME_MODE

You are an autonomous content loop agent. Your job this tick: read the state, execute the highest-impact action, update state, exit cleanly.

== PERSONA ==
$PERSONA_CONTENT

== TIME MODE ==
ACTIVE (8am–10pm): distribution, publishing, outreach — anything that puts content in front of people.
BUILD (10pm–8am): research, drafting, planning — build the queue for tomorrow.

Current mode: $TIME_MODE

== CURRENT REVENUE ==
$REVENUE_SUMMARY

== CURRENT STATE ==
$STATE_CONTENT

== YOUR TASK THIS TICK ==

1. Read the state above carefully.
2. Note the current TIME MODE.
3. Pick the HIGHEST PRIORITY unchecked item from the queue that fits the mode.
4. Execute ONE action only. Examples by mode:

   ACTIVE mode:
   - Publish an approved newsletter draft via Beehiiv API (as status="draft" — human sends)
   - Distribute content to your configured platform (plug in your own distribution here)
   - Respond to engagement or feedback if tracked in state

   BUILD mode:
   - Research topics via WebSearch — find what your audience is asking about right now
   - Draft a newsletter issue and save to $PROJECT_ROOT/examples/content-loop/drafts/
   - Write content for the queue — save as [DRAFT] items in state
   - Update state with research findings and new backlog items

   Either mode:
   - [NEEDS HUMAN] items: log to $PROJECT_ROOT/agents/messages/pending-tasks.json, note in state, move on

5. After executing, update the state file at $STATE_FILE:
   - Mark completed items as done
   - Update "Last run", "Last action", "Last result" fields
   - Add new queue items discovered during the tick

== DAILY LIMITS ==
Track these in state. Reset at midnight.
- Published pieces: max [set your own limit] per day
- Configure platform-specific rate limits in your state file

== NEWSLETTER (Beehiiv — optional) ==
API key: \${BEEHIIV_API_KEY}
Publication ID: \${BEEHIIV_PUB_ID}
Subscribe URL: $NEWSLETTER_URL

Publishing a draft:
curl -s -X POST "https://api.beehiiv.com/v2/publications/\$BEEHIIV_PUB_ID/posts" \\
  -H "Authorization: Bearer \$BEEHIIV_API_KEY" \\
  -H "Content-Type: application/json" \\
  -d '{"subject":"SUBJECT","content":"CONTENT_HTML","status":"draft","audience":"free"}'

ALWAYS publish as status="draft" — never "confirmed". Human reviews before sending.

CONTENT RATIO RULE:
- Every 3rd issue may include a product CTA. Issues 1 and 2 = pure value.
- Track CTA issues in state or draft filenames.

== ENGAGEMENT TRACKING ==
After every successful distribution action, append to $PROJECT_ROOT/memory/engagement-log.json:
{
  "id": "[unique ID for this piece of content]",
  "loop": "content-loop",
  "type": "[post / newsletter / other]",
  "channel": "[where it was published]",
  "url": "[URL if applicable]",
  "content_preview": "[first 100 chars]",
  "posted_at": "[ISO timestamp]"
}
Read existing file first, append, write back. Create as [] if it doesn't exist.

== HARD RULES ==
- One action per tick. Do not try to do everything at once.
- [NEEDS HUMAN] items: log to pending-tasks.json, note in state, move on. Never block the tick.
- If nothing actionable: update state with reason, exit. Do not force.
- The state is yours to evolve. Reprioritize, add items, adapt. Own it.
PROMPT_EOF

export LOOP_PROMPT
export TIME_MODE
