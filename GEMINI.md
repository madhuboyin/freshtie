# Freshtie - Gemini Mandates

## Project Overview
Freshtie is a conversation continuity assistant designed to help users prepare for social interactions. It surfaces instant conversation prompts based on captured notes about individuals. The project is an iOS-first, local-first MVP.

## Repository Structure
- **`app/ios/`**: Native Swift/SwiftUI app (Primary focus).
- **`app/backend/`**: Minimal Node.js HTTP server (health/validation only).
- **`infra/k8s/`**: Kustomize-based Kubernetes manifests for RPi K3s cluster.
- **`docs/`**: Architecture, decisions (ADRs), and functional requirements (FRD).
- **`ops/`**: Monitoring and runbooks.

## Development Commands

### iOS App (`app/ios/`)
- **Open Project**: `open app/ios/Freshtie.xcodeproj`
- **Target**: iOS 17+ (SwiftData requirement).
- **Tests**: Run `FreshtieTests` in Xcode.

### Backend (`app/backend/`)
- **Dev**: `cd app/backend && npm run dev`
- **Start**: `cd app/backend && npm start`
- **Health Check**: `curl http://127.0.0.1:3000/health`

### Infrastructure & Ops
- **Deploy Prod**: `./infra/scripts/deploy-prod.sh` or `kubectl apply -k infra/k8s/overlays/prod`
- **Logs**: `./infra/scripts/logs.sh`
- **Port-Forward**: `./infra/scripts/port-forward.sh`

## Architecture & Patterns

### iOS (Local-First)
- **Framework**: SwiftUI + SwiftData.
- **Persistence**: `ModelContainer.freshtie` (on-disk) and `ModelContainer.preview` (in-memory seeded).
- **Architecture**: Feature-based folder structure (Home, Person, Capture, PromptEngine, etc.).
- **Models**:
  - `Person`: `@Model` with unique ID, notes relationship (cascade delete).
  - `Note`: `@Model` with raw text and person relationship.
- **Prompt Engine**: Deterministic logic (not LLM-based for MVP). Pipeline: Keyword Extraction → Categorization → Temporal Logic → Template Library.

### Backend (Stateless)
- **Framework**: Bare Node.js (no Express/FastAPI).
- **Ports**: Runs on 3000.
- **Routes**: `GET /` and `GET /health`.

## Key Mandates
1. **iOS-First**: Prioritize UX quality and native integration.
2. **Local-First**: Core functionality must work offline; prompts are deterministic.
3. **Minimal Backend**: Keep backend logic to an absolute minimum (operational readiness).
4. **Environment**: Production-only (`prod`) on Raspberry Pi k3s cluster; no staging env.
5. **Coding Style**: Follow existing feature-based organization in iOS and minimal dependency approach in backend.

---
*Updated for gemini-cli v0.36.0*
