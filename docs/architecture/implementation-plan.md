Freshtie End-to-End Implementation Plan
1. Goal

Ship a testable iOS MVP that proves one thing:

Will users come back and use Freshtie again within a week without being reminded?

The MVP should include:

person selection

instant prompts

optional quick capture

local prompt engine

lightweight contact-assisted entry

minimal backend + k8s deployment for future expansion and operational readiness

2. Product Scope for MVP
In scope

iOS app in Swift / SwiftUI

manual person selection from contacts

person screen with instant prompts

optional voice/text capture

deterministic local prompt engine

simple recent people list

optional contact-share entry path

tiny backend with /health

deployment into Raspberry Pi K3s namespace freshtie

Out of scope

auth

multi-user sync

LLM-based prompt generation

subscriptions

analytics warehouse

Android

test environment

advanced notifications

3. Delivery Phases
Phase 0 — Foundation and Repo Bootstrap
Objective

Prepare repo, infra, and development baseline.

Tasks

create git repo freshtie

create namespace freshtie

commit scaffold

deploy tiny backend /health

verify pod health, service reachability, and scripts

Deliverables

repo initialized

namespace created

backend deployed on K3s

deployment scripts working

Exit criteria

kubectl -n freshtie get pods is healthy

curl /health succeeds via port-forward

Phase 1 — iOS App Shell
Objective

Create the native app shell and navigation foundation.

Tasks

create Xcode project in app/ios

define app structure:

Home

Person Detail

Quick Capture

Settings

establish design system tokens:

spacing

typography

colors

prompt chip styles

create reusable components:

person row

prompt chip

search field

section header

empty state block

Deliverables

navigable iOS shell

polished basic UI foundation

Exit criteria

app launches cleanly

user can navigate Home → Person → Capture

Phase 2 — Local Data Layer
Objective

Build the first local-only data layer so the app works without backend dependency.

Tasks

choose storage:

SwiftData preferred

Core Data if you want broader manual control

define models:

Person

Note

PromptHistory optional

store:

recent people

notes

prompt refresh state

create repositories/services:

PersonStore

NoteStore

PromptStore

Suggested models

Person

id

displayName

contactIdentifier optional

createdAt

lastOpenedAt

lastInteractionAt optional

Note

id

personId

rawText

createdAt

sourceType (manual / voice / share)

PromptCache optional

personId

prompts[]

generatedAt

Deliverables

persistent local storage

recent people retained between launches

Exit criteria

add/select people and notes persist after app restart

Phase 3 — Contacts Integration (Manual First)
Objective

Enable manual person selection without over-relying on permissions early.

Tasks

integrate Contacts picker

support manual search/select from contacts

store selected contact’s display name + identifier

create fallback for users who decline contacts permission:

manual typed person entry

Deliverables

select contact manually

create person from contact

typed fallback path

Exit criteria

user can add a person with or without granting contacts access

Phase 4 — Prompt Engine (Core MVP Logic)
Objective

Implement the deterministic local prompt engine.

Tasks

build keyword extraction rules

build category mapping:

job

travel

life event

family

school

move

build temporal logic:

future vs past phrasing

build template library

build generic fallback prompt set

build prompt refresh rotation

Engine pipeline

read latest note(s)

extract keywords

map keyword → category

apply temporal logic

generate 1–2 prompts

if nothing usable, return generic prompts

Example

Input:

“starting new job at Google next Monday”

Output:

“How are things preparing for the new role at Google?”
Later:

“How are things settling in at Google?”

Deliverables

local prompt engine service

prompt tests

Exit criteria

prompt generation is instant and feels correct for sample notes

Phase 5 — Home Screen (Value-First Entry)
Objective

Deliver immediate value on launch.

Tasks

implement Home screen with:

greeting

search / pick person CTA

recent people

frequently contacted optional

support direct navigation to person page

keep layout minimal, not dashboard-like

Deliverables

usable home screen

fast entry into value moment

Exit criteria

from launch, user can select someone and reach useful prompts in under 2 taps

Phase 6 — Person Screen (Core Product Experience)
Objective

Build the core conversation continuity experience.

Tasks

render:

person header

last time summary if available

prompt chips

prompt refresh

“add something optional”

support no-data mode:

generic prompts only

support low-data mode:

one note + one prompt

support richer mode:

summary + contextual prompts

Deliverables

complete Person screen

prompt refresh interaction

empty and populated states

Exit criteria

user selects a person and instantly sees helpful prompts whether or not notes exist

Phase 7 — Quick Capture (Ultra-Light)
Objective

Make capture optional, fast, and non-annoying.

Tasks

voice-first quick capture screen

text entry fallback

auto-save after silence or save tap

no tagging required in MVP

optionally show “saved” microfeedback and return automatically

Stretch if easy

background waveform / listening animation

one-tap capture from person screen

Deliverables

≤3 second quick capture flow

saved notes available to prompt engine

Exit criteria

user can add a note with minimal friction and see later prompts improve

Phase 8 — Share Extension
Objective

Add the highest-signal optional entry point.

Tasks

create iOS share extension

allow sharing a contact into Freshtie

parse shared contact name

open capture + person flow

add onboarding hint explaining the feature

Deliverables

share extension target

first-use hint

Exit criteria

from Contacts share sheet, user can send a contact into Freshtie and land in capture flow

Phase 9 — Lightweight Contact Detection
Objective

Add passive assist without depending on it as primary value.

Tasks

implement foreground contact diff

persist last known contact snapshot metadata

detect newly added contacts on app open/resume

apply timing model:

fresh

warm

stale

expired

suppress bad timing states

Important

This is assistive, not primary. The app must still work great without it.

Deliverables

passive detection service

contextual prompt surface

Exit criteria

newly added contacts can surface contextually on next app open without feeling stale

Phase 10 — Permission Strategy + Settings
Objective

Ask for permissions only after value is demonstrated.

Tasks

do not ask contacts at launch

after user manually adds 1–2 people and sees prompts, show upgrade prompt:

“Want this to happen automatically when you save a contact?”

build Settings screen:

contacts permission status

notifications status placeholder

app version

Deliverables

delayed permission flow

graceful permission-denied mode

Exit criteria

app remains fully usable even when contacts are denied

Phase 11 — Local Analytics / Validation Instrumentation
Objective

Measure whether the behavior works before building more.

Tasks

Instrument:

app_open

person_selected

prompt_viewed

prompt_refreshed

note_added

share_extension_used

contacts_permission_prompted

contacts_permission_granted

return_visit_d1 / d7

interaction_with_2plus_people

For MVP, these can be:

local logs

simple backend ingestion later

or lightweight event batching to backend when ready

Deliverables

event taxonomy

instrumentation hooks

Exit criteria

you can answer:

did user come back?

did user view prompts?

did user add a note?

did they use more than one person?

Phase 12 — Backend Expansion (Minimal but Useful)
Objective

Keep backend tiny but prepare for future services.

Initial scope

/health

/version

/config/prompts optional

/events optional for analytics ingestion

Tasks

add endpoints safely

add request logging

keep stateless

wire container image build

Deliverables

backend ready for future analytics/config

still lightweight for Pi cluster

Exit criteria

backend supports minimal support functions without adding product dependency

Phase 13 — CI/CD and Deployment Hardening
Objective

Make deployments repeatable and safe.

Tasks

GitHub Actions:

backend CI

optional Docker build

deploy workflow later

add image build for ARM-compatible deployment if needed

wire private registry secret if applicable

validate K8s manifests on push

document rollout and rollback

Deliverables

stable deployment pipeline

clean operational runbooks

Exit criteria

backend can be rebuilt and redeployed consistently

Phase 14 — Prototype Validation Sprint
Objective

Test the real behavior with real users.

Test group

10–20 users to start

prioritize:

students

socially active users

networking-heavy users

Questions to validate

do they get value immediately?

do they come back unprompted?

do they ever use it before talking to someone?

do they add notes more than once?

do they understand share extension?

Success criteria

D7 retention around or above 30%

prompt views are frequent

at least some repeat capture behavior

user language includes:

“this is useful”

“I would use this before meeting someone”

“this helped me remember what to say”

4. Recommended Implementation Order

If you want the most efficient path, do it in this order:

Phase 0 — repo + K8s + health backend

Phase 1 — iOS shell

Phase 2 — local data layer

Phase 5 — Home

Phase 6 — Person screen

Phase 4 — prompt engine

Phase 7 — quick capture

Phase 10 — permission strategy

Phase 8 — share extension

Phase 9 — contact diff

Phase 11 — instrumentation

Phase 12/13 — backend expansion + CI/CD

Phase 14 — user validation

This order gets you to user testing fastest.

5. Suggested Milestones
Milestone A — Infra Ready

repo scaffold complete

namespace created

/health backend deployed

Milestone B — Value-First App Ready

Home + Person screen

deterministic prompts

no-data mode

local persistence

Milestone C — Capture Compounding Ready

voice/text capture

notes improve prompts

Milestone D — Trigger-Assisted Ready

share extension

contact diff

permission sequencing

Milestone E — Validation Ready

instrumentation

prototype users

retention measurement

6. Suggested Ownership Model

If you are doing this solo or with a small team:

Track A — Product / UX

flows

copy

prompt quality

prototype feedback

Track B — iOS

screens

local storage

contacts

share extension

capture

Track C — Infra / Backend

repo

Docker

K8s

tiny backend

deployment scripts

event ingestion later

7. Definition of MVP Done

MVP is done when all of this is true:

user can open Freshtie

select a person

see useful prompts instantly

optionally add a quick note

later reopen and see slightly better prompts

app works without LLM

app works without mandatory contacts permission

backend /health is deployed in freshtie

you can test with real users

8. What Not to Do Yet

Do not spend time yet on:

subscriptions

fancy analytics dashboards

complex backend APIs

cloud sync

Android

advanced notification campaigns

AI prompt generation

deep k8s multi-env setup

9. Immediate Next Actions

For the next 3 concrete steps, I recommend:

Step 1

Finish the infra bootstrap and deploy the tiny backend to namespace freshtie.

Step 2

Create the SwiftUI app shell with:

Home

Person

Capture

Step 3

Implement the local deterministic prompt engine before any trigger automation.

That gets you to a usable MVP fastest.

If you want, I can turn this into a phase-by-phase build checklist with exact tasks and file targets.