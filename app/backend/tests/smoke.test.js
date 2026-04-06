'use strict';

const http = require('http');

const PORT = process.env.PORT || 3000;
const BASE_URL = `http://127.0.0.1:${PORT}`;

async function request(path, method = 'GET', body = null) {
    return new Promise((resolve, reject) => {
        const bodyStr = body !== null ? JSON.stringify(body) : null;
        const options = {
            method,
            headers: {
                'Content-Type': 'application/json',
                ...(bodyStr ? { 'Content-Length': Buffer.byteLength(bodyStr) } : {})
            }
        };
        const req = http.request(`${BASE_URL}${path}`, options, (res) => {
            let data = '';
            res.on('data', chunk => { data += chunk; });
            res.on('end', () => {
                try {
                    resolve({ statusCode: res.statusCode, body: data ? JSON.parse(data) : null });
                } catch {
                    resolve({ statusCode: res.statusCode, body: data });
                }
            });
        });
        req.on('error', reject);
        if (bodyStr) req.write(bodyStr);
        req.end();
    });
}

function assert(condition, label) {
    if (!condition) throw new Error(`Assertion failed: ${label}`);
}

async function runTests() {
    console.log('🚀 Running backend smoke tests...\n');
    let passed = 0;

    // ── GET /health ──────────────────────────────────────────────────────────
    {
        const res = await request('/health');
        assert(res.statusCode === 200, '/health → 200');
        assert(res.body.status === 'ok', '/health → status: ok');
        assert(typeof res.body.uptimeSeconds === 'number', '/health → uptimeSeconds is a number');
        console.log('✅ GET /health');
        passed++;
    }

    // ── GET /version ─────────────────────────────────────────────────────────
    {
        const res = await request('/version');
        assert(res.statusCode === 200, '/version → 200');
        assert(typeof res.body.version === 'string', '/version → version is a string');
        assert(typeof res.body.buildSha === 'string', '/version → buildSha is a string');
        console.log('✅ GET /version');
        passed++;
    }

    // ── GET /config/prompts ──────────────────────────────────────────────────
    {
        const res = await request('/config/prompts');
        assert(res.statusCode === 200, '/config/prompts → 200');
        assert(res.body.promptConfig, '/config/prompts → has promptConfig');
        assert(Array.isArray(res.body.promptConfig.enabledCategories), '/config/prompts → enabledCategories is array');
        assert(res.body.featureFlags, '/config/prompts → has featureFlags');
        console.log('✅ GET /config/prompts');
        passed++;
    }

    // ── POST /events — single valid event ────────────────────────────────────
    {
        const payload = { eventName: 'app_opened', timestamp: new Date().toISOString() };
        const res = await request('/events', 'POST', payload);
        assert(res.statusCode === 202, 'POST /events single → 202');
        assert(res.body.count === 1, 'POST /events single → count: 1');
        console.log('✅ POST /events (single)');
        passed++;
    }

    // ── POST /events — batch (array) ─────────────────────────────────────────
    {
        const payload = [
            { eventName: 'person_selected', timestamp: new Date().toISOString() },
            { eventName: 'prompt_viewed',   timestamp: new Date().toISOString() }
        ];
        const res = await request('/events', 'POST', payload);
        assert(res.statusCode === 202, 'POST /events batch → 202');
        assert(res.body.count === 2, 'POST /events batch → count: 2');
        console.log('✅ POST /events (batch)');
        passed++;
    }

    // ── POST /events — missing required fields → 400 ─────────────────────────
    {
        const payload = { eventName: 'missing_timestamp' }; // no timestamp
        const res = await request('/events', 'POST', payload);
        assert(res.statusCode === 400, 'POST /events malformed → 400');
        assert(res.body.error === true, 'POST /events malformed → error: true');
        console.log('✅ POST /events (malformed → 400)');
        passed++;
    }

    // ── POST /events — empty body → 400 ──────────────────────────────────────
    {
        const res = await request('/events', 'POST');
        assert(res.statusCode === 400, 'POST /events empty → 400');
        console.log('✅ POST /events (empty body → 400)');
        passed++;
    }

    // ── GET / (root) ─────────────────────────────────────────────────────────
    {
        const res = await request('/');
        assert(res.statusCode === 200, 'GET / → 200');
        assert(Array.isArray(res.body.endpoints), 'GET / → endpoints is array');
        console.log('✅ GET / (root)');
        passed++;
    }

    // ── 404 on unknown route ─────────────────────────────────────────────────
    {
        const res = await request('/not-a-real-route');
        assert(res.statusCode === 404, 'GET /unknown → 404');
        assert(res.body.error === true, 'GET /unknown → error: true');
        console.log('✅ GET /unknown (→ 404)');
        passed++;
    }

    console.log(`\n🎉 All ${passed} tests passed.`);
    process.exit(0);
}

runTests().catch(err => {
    console.error('❌ Tests failed:', err.message);
    process.exit(1);
});
