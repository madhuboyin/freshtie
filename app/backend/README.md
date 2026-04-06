# Freshtie Backend

Minimal but future-ready backend service for Freshtie.

## Endpoints

- `GET /health` - Service health and uptime. Used for K8s probes.
- `GET /version` - Deployed version and build info.
- `GET /config/prompts` - Lightweight remote configuration for prompt engine and feature flags.
- `POST /events` - Analytics event ingestion. Accepts JSON payload or array of events.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3000` | Server port |
| `NODE_ENV` | `development` | Environment mode |
| `APP_NAME` | `freshtie` | Application name |
| `APP_VERSION` | *(from package.json)* | Service version string |
| `BUILD_SHA` | `unknown` | Git commit SHA injected at build/deploy time |
| `LOG_LEVEL` | `info` | Logging verbosity |
| `EVENTS_ENABLED` | `true` | Enable/disable event ingestion endpoint |
| `PROMPT_CONFIG_VERSION` | `1.0.0` | Version token for the `/config/prompts` response |

## Development

```bash
cd app/backend
npm install
npm run dev
```

## Testing

```bash
npm test
```

## Operational Notes

- **Stateless**: The service is completely stateless.
- **Logging**: Uses structured JSON logging for standard output (stdout).
- **Event Ingestion**: Currently logs events to stdout in structured format. Future phases can add a database or queue sink.
