Feature Requirements Document (FRD v6.2 — Final)
Product: (Working Name) — Conversation Continuity Assistant (iOS, Native Swift)
1. 🎯 Objective

Build a mobile-first iOS application that helps users:

Know what to say before talking to someone — instantly, with or without prior input.

The system must:

deliver immediate value (no data required)

leverage natural triggers where available

support ultra-fast optional capture (≤3 seconds)

work reliably with low engagement (10–15% capture rate)

2. 🧩 Problem Statement

Users:

forget prior conversations

struggle to restart interactions naturally

don’t capture context at the right moment

Existing tools fail because:

they require effort before value

they depend on discipline

they are slow or overcomplicated

3. 🔥 Core Product Insight

The best moment to help is before a conversation, but the best moment to capture is right after meeting someone.

4. ⚠️ Product Strategy (Final Model)
System Flow:
1. Entry

manual open (primary)

trigger-assisted (secondary)

2. Immediate Value

show prompts instantly (no data required)

3. Optional Capture

ultra-light, voice-first

4. Compounding Value

prompts improve over time

5. 🧠 Product Principles

Value First, Always

Speed > Intelligence (MVP)

Capture is Optional

<3 Second Interaction Target

Better No Prompt Than Wrong Prompt

Deterministic > AI (MVP)

6. 🔁 Core Behavioral Loop
Entry Paths
A. Manual (Primary)

open app

select person

B. Trigger-Assisted (Secondary)

share extension

contact detection (foreground)

Core Experience

Select person

View prompts instantly

Feel prepared

(Optional) capture note

Future prompts improve

7. ⚡ Trigger System (Balanced)
7.1 Trigger Types
🥇 Share Extension (High-Signal, Optional)
Contacts → Share → App → Capture + Prompts

intentional action

high conversion

NOT assumed default

🥈 Foreground Contact Detection

detect new contacts when app opens

show contextual suggestion

🥉 Manual Entry (Primary Path)

always available

core usage mode

7.2 Trigger Timing Model
🟢 Fresh (0–15 min)

“You just met [Name] — add one thing before you forget”

🟡 Warm (15 min – 6 hrs)

“You recently met [Name] — add something while it’s fresh”

🔵 Stale (6–48 hrs)

“You added [Name] yesterday — anything you remember?”

⚫ Expired (>48 hrs)

no trigger shown

👉 Rule:
Suppress stale or irrelevant triggers

7.3 Share Extension Discoverability
Onboarding:

“You can also capture instantly:
Contacts → Share → App”

First Trigger Hint:

“Tip: Share directly from Contacts next time”

8. 📱 Feature Scope (MVP)
8.1 Person Selection

search contacts manually

fast, native picker

8.2 Instant Prompts (CORE)
Requirements:

render instantly (<300ms)

no API dependency

Case: No Data
• What have you been up to lately?
• Anything new since we last spoke?
Case: With Data
• How’s your new job going?
• Did you go on that trip?
8.3 Prompt Refresh System (NEW)
Behavior:

user taps “↻ New ideas”

system rotates prompt set

Constraints:

instant

deterministic

max 3–5 variations

8.4 Quick Capture (OPTIONAL)
Flow:

Tap → Speak → Auto-save → Done

Rules:

no confirmation

no tagging required

voice-first

👉 Target:
≤3 seconds

8.5 Context Display
Minimal:
Last time:
“Started new job, planning trip”
8.6 Zero-Input Fallback (PRIMARY MODE)

App must be useful without any stored data

8.7 Home Screen
Sections:

Recent People

Frequently Contacted

👉 No complex ranking logic in MVP

8.8 Nudges (Limited)
Types:

missed capture

inactivity

Limits:

max 2/week

person-specific

9. 🧠 Prompt Engine (CORE SYSTEM)
9.1 Architecture
Step 1: Keyword Extraction

Example:
“Starting new job at Google”

→ ["job", "Google"]

Step 2: Categorization
Keyword	Category
job	professional
baby	life_event
trip	travel
Step 3: Temporal Logic Engine (NEW)
Rules:

detect future indicators:

“next”, “Friday”, “soon”

compare with current time

Output:
Case	Prompt
Future	“How is X going?”
Past	“How did X go?”
Step 4: Template Mapping

Example:

Category	Template
job	“How’s your new job going?”
travel	“How did your trip go?”
9.2 Constraints

no LLM

fully local

deterministic

instant execution

10. 🔐 Privacy Model
Principles:

no background tracking

no passive listening

no auto data ingestion

Contacts:

permission requested after value

optional

11. 💰 Monetization
Deferred until:

retention validated

Future:

AI-powered prompts

deeper insights

12. 📊 Success Metrics
Primary:

👉 D7 Retention ≥30%

Supporting:

prompt view rate ≥60%

multi-person usage ≥50%

capture rate ≥10%

13. 🚀 Onboarding
Flow:

Select a person

See prompts instantly

Then:
“Want to remember something next time?”

14. 📣 Distribution Strategy
Core Mechanism:

visible during contact exchange

Channels:

students (primary)

social scenarios

networking events

15. ⚠️ Risks & Mitigations
Low capture rate

→ system works without data

Trigger dependency

→ manual path is primary

Poor prompts

→ deterministic logic + refresh

16. 🧱 Tech Stack
Platform:

iOS-first

Frontend:

Swift (native)

Backend:

optional / local-first

17. 🧠 Signal Model
Signal	Output
None	generic prompts
Low	keyword prompts
High	contextual prompts
18. 🛡️ Competitive Positioning

Own the moment before conversations, not the data after them.

19. 🧭 Final Product Definition

A fast, lightweight assistant that helps you know what to say before talking to someone — instantly, and improves over time.