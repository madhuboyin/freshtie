# Internal: Prototype Validation Sprint Guide

## Objective
Validate the core Freshtie MVP with 5–10 real users to answer:
**“Will users come back and use this again without being reminded?”**

## Preparation
- **Build**: Use the latest Phase 14 stable build.
- **Environment**: Local-only; no backend connectivity required for core value.
- **Reset**: Between testers, long-press the **Version number** in Settings to access the **Validation Support** menu and select **Reset Everything**.

## Tester Tasks
1. **The Prep**: "Imagine you're about to see a friend or colleague. Add them to Freshtie and see what it suggests you talk about."
2. **The Memory**: "Imagine you just finished a conversation and want to remember one important detail. Use Quick Capture to save it."
3. **The Repeat**: "Open the app again later in the day. Look at the person you added — how do the suggestions feel now?"

## Signals to Watch
- **Retention**: Check `app_opened` events over several days.
- **Utility**: Ratio of `person_selected` to `prompt_viewed`.
- **Engagement**: Usage of `prompt_refreshed`.
- **Capture**: Percentage of sessions that result in a `note_added`.

## How to Inspect Results
In the hidden **Validation Support** menu (Settings -> Long press Version), scroll down to **Recent Events** to see a live log of local behavioral data.
