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

3. **`app/ios`** — Native Swift/SwiftUI. Phase 3 (contacts) complete (see below).

### iOS architecture

Open with Xcode: `open app/ios/Freshtie.xcodeproj`

**Phase 2 (current)** adds a full SwiftData local persistence layer. The project targets **iOS 17** (minimum for SwiftData) and uses `GENERATE_INFOPLIST_FILE = YES` (no manual Info.plist).

**Source layout** under `app/ios/Freshtie/`:

| Folder | Purpose |
|--------|---------|
| `App/` | `FreshtieApp` entry point + `RootView` (TabView) |
| `Data/Persistence/` | `FreshtieContainer.swift` — `ModelContainer.freshtie` (on-disk) + `ModelContainer.preview` (in-memory, seeded) |
| `Data/Repositories/` | `PersonRepository.swift` — stateless `enum` with sort/mutation helpers |
| `Data/Seed/` | `SeedData.swift` — dev/preview seed data |
| `DesignSystem/` | `AppColors`, `AppTypography`, `AppSpacing` tokens + `Components/` |
| `DesignSystem/Components/` | `AvatarView`, `PersonRow`, `PromptChip`, `SectionHeader`, `SearchSelectRow` |
| `Features/Home/` | `HomeView` + `AddPersonSheet` — greeting, search row, recent-people list |
| `Features/Person/` | `PersonView` — avatar header, context summary, prompt chips, notes section, capture CTA |
| `Features/Capture/` | `CaptureView` + `CapturePersonPickerView` — mic button, waveform animation, text fallback |
| `Features/Settings/` | `SettingsView` — contacts permission status + version rows |
| `Features/Contacts/` | `ContactPickerRepresentable`, `ContactPermissionService`, `ContactMapper`, `ContactDeniedView` |
| `Models/` | `Person` (@Model), `Note` (@Model), `Prompt` (plain struct) |
| `PreviewSupport/` | `PreviewData` — bare instances for component previews; screens use `.modelContainer(.preview)` |

**Data models**:
- `Person` — `@Model` with `@Attribute(.unique) id`, `displayName`, `createdAt`, `lastOpenedAt?`, `lastInteractionAt?`, `creationSource`, `isPinned`, `notes: [Note]` (cascade delete). Computed: `initials`, `lastContext` (most recent note rawText), `lastInteractionLabel` (relative date string).
- `Note` — `@Model` with `id`, `rawText`, `createdAt`, `sourceType`, `person: Person?` (back-reference for the cascade inverse).

**Navigation model**: `TabView` (Home / Capture / Settings). Home tab has its own `NavigationStack`; tapping a person pushes `PersonView`. Capture tab shows `CapturePersonPickerView` (pick person first), then pushes `CaptureView(person:)`. `CaptureView` also reachable as a sheet from `PersonView`.

**Design tokens**: `AppColors.accent = Color.indigo`. All spacing from `AppSpacing`, corner radii from `AppRadius`, fixed sizes from `AppSize`.

**Contacts integration** (Phase 3): `SearchSelectRow` → `.confirmationDialog` → "Pick from Contacts" or "Add Manually". `ContactPermissionService` checks/requests `CNContactStore` auth before presenting `ContactPickerRepresentable` (UIKit bridge). `ContactMapper.findOrCreate` deduplicates by `contactIdentifier`. Denied/restricted paths show `ContactDeniedView` with a Settings deep-link and manual fallback. `NSContactsUsageDescription` is set via `INFOPLIST_KEY_` build setting (no manual Info.plist).

**TODOs for future phases** (left as `// TODO:` comments in code):
- Phase 4: Replace static `prompts` array with `PromptEngine.prompts(for:)`
- Phase 7: Integrate `AVAudioSession` + `SFSpeechRecognizer` in `CaptureView`
- Phase 10: Full notification permission checks in `SettingsView`

**Planned (not yet built)**: `PromptCache` model, `PromptEngine`, Share Extension.

### CI

GitHub Actions runs on push to `main` and PRs. Backend check: install, start server, curl `/health`. No test framework yet — the smoke test is the only automated check. Deploy workflow (`deploy-prod.yml`) is a placeholder stub.

## Key decisions

- **iOS-first**: Fastest path to validating UX quality (ADR 0001)
- **Local-first MVP**: Core app works without any backend; prompts are deterministic, not LLM-generated (ADR 0002)
- **Prod-only environment**: No staging/test K8s env until validation is complete (ADR 0003)
- **Backend scope**: Keep the backend tiny and stateless; it exists for operational readiness and future expansion, not MVP product logic
