# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is Freshtie

Freshtie is a conversation continuity assistant — it helps users know what to say before talking to someone. The iOS app surfaces instant conversation prompts based on notes captured about a person. The backend is intentionally minimal (health/validation only for now).

## Commands

### Backend (`app/backend`)

```bash
# Run locally (with file watch)
cd app/backend && npm run dev

# Run for production
cd app/backend && npm start

# Smoke test (mirrors CI)
node src/server.js &
sleep 2
curl http://127.0.0.1:3000/health
```

### Infrastructure

```bash
# Deploy to prod
kubectl apply -k infra/k8s/overlays/prod
kubectl -n freshtie rollout status deployment/freshtie-api

# Or via script
./infra/scripts/deploy-prod.sh

# Other ops scripts
./infra/scripts/logs.sh
./infra/scripts/port-forward.sh
./infra/scripts/restart.sh
```

## Architecture

### Current state

The repo has three active layers:

1. **`app/backend`** — A bare Node.js HTTP server (no framework). Only two routes exist: `GET /` and `GET /health`. No dependencies beyond Node stdlib. Runs on port 3000.

2. **`infra/k8s`** — Kustomize-based Kubernetes manifests. Structure is `base/` + `overlays/prod/`. Deployed to a Raspberry Pi K3s cluster in the `freshtie` namespace. Single replica. Health/liveness probes hit `/health`. Env vars come from a ConfigMap (`freshtie-config`) and a Secret (`freshtie-secrets`).

3. **`app/ios`** — Native Swift/SwiftUI. Phase 1 shell complete (see below).

### iOS architecture

Open with Xcode: `open app/ios/Freshtie.xcodeproj`

**Phase 1 shell** is a navigable UI with mock data only (no persistence, no backend, no contacts). The project targets **iOS 16** and uses `GENERATE_INFOPLIST_FILE = YES` (no manual Info.plist).

**Source layout** under `app/ios/Freshtie/`:

| Folder | Purpose |
|--------|---------|
| `App/` | `FreshtieApp` entry point + `RootView` (TabView) |
| `DesignSystem/` | `AppColors`, `AppTypography`, `AppSpacing` tokens + `Components/` |
| `DesignSystem/Components/` | `AvatarView`, `PersonRow`, `PromptChip`, `SectionHeader`, `SearchSelectRow` |
| `Features/Home/` | `HomeView` — greeting, search row, recent-people list |
| `Features/Person/` | `PersonView` — avatar header, context summary, prompt chips, capture CTA |
| `Features/Capture/` | `CaptureView` — mic button, waveform animation, text fallback; works as tab or sheet |
| `Features/Settings/` | `SettingsView` — placeholder permission + version rows |
| `Models/` | `Person` (Identifiable, Hashable), `Prompt` (Identifiable) |
| `PreviewSupport/` | `PreviewData` — all mock data for previews; replace in Phase 2 |

**Navigation model**: `TabView` (Home / Capture / Settings). Home tab has its own `NavigationStack`; tapping a person pushes `PersonView`. `CaptureView` is reached from the Capture tab (`isSheet: false`) or as a sheet from `PersonView` (`isSheet: true`).

**Design tokens**: `AppColors.accent = Color.indigo`. All spacing from `AppSpacing`, corner radii from `AppRadius`, fixed sizes from `AppSize`.

**Phase 1 TODOs for future phases** (left as `// TODO:` comments in code):
- Phase 2: Replace `PreviewData` with SwiftData/`PersonStore`/`NoteStore`
- Phase 3: Wire `SearchSelectRow` to `CNContactPickerViewController`
- Phase 4: Replace static `prompts` array with `PromptEngine.prompts(for:)`
- Phase 7: Integrate `AVAudioSession` + `SFSpeechRecognizer` in `CaptureView`
- Phase 10: Real permission checks in `SettingsView`

**Planned (not yet built)**: `Note` model, `PromptCache` model, `PersonStore`, `NoteStore`, `PromptStore`, Share Extension.

### CI

GitHub Actions runs on push to `main` and PRs. Backend check: install, start server, curl `/health`. No test framework yet — the smoke test is the only automated check. Deploy workflow (`deploy-prod.yml`) is a placeholder stub.

## Key decisions

- **iOS-first**: Fastest path to validating UX quality (ADR 0001)
- **Local-first MVP**: Core app works without any backend; prompts are deterministic, not LLM-generated (ADR 0002)
- **Prod-only environment**: No staging/test K8s env until validation is complete (ADR 0003)
- **Backend scope**: Keep the backend tiny and stateless; it exists for operational readiness and future expansion, not MVP product logic
