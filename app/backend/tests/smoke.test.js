'use strict';

const http = require('http');

const PORT = process.env.PORT || 3000;
const BASE_URL = `http://127.0.0.1:${PORT}`;

async function request(path, method = 'GET', body = null) {
    return new Promise((resolve, reject) => {
        const options = {
            method,
            headers: {
                'Content-Type': 'application/json'
            }
        };
        const req = http.request(`${BASE_URL}${path}`, options, (res) => {
            let data = '';
            res.on('data', chunk => { data += chunk; });
            res.on('end', () => {
                resolve({
                    statusCode: res.statusCode,
                    body: data ? JSON.parse(data) : null
                });
            });
        });
        req.on('error', reject);
        if (body) req.write(JSON.stringify(body));
        req.end();
    });
}

async function runTests() {
    console.log('🚀 Running backend expansion smoke tests...');
    
    try {
        // Test /health
        const health = await request('/health');
        console.log('✅ GET /health:', health.statusCode);
        if (health.statusCode !== 200 || health.body.status !== 'ok') throw new Error('/health failed');

        // Test /version
        const version = await request('/version');
        console.log('✅ GET /version:', version.statusCode);
        if (version.statusCode !== 200 || !version.body.version) throw new Error('/version failed');

        // Test /config/prompts
        const config = await request('/config/prompts');
        console.log('✅ GET /config/prompts:', config.statusCode);
        if (config.statusCode !== 200 || !config.body.promptConfig) throw new Error('/config/prompts failed');

        // Test /events
        const eventPayload = { eventName: 'test_event', timestamp: new Date().toISOString() };
        const events = await request('/events', 'POST', eventPayload);
        console.log('✅ POST /events:', events.statusCode);
        if (events.statusCode !== 202) throw new Error('/events failed');

        // Test 404
        const notFound = await request('/not-a-real-route');
        console.log('✅ GET /404:', notFound.statusCode);
        if (notFound.statusCode !== 404) throw new Error('404 failed');

        console.log('🎉 All backend expansion tests passed!');
        process.exit(0);
    } catch (err) {
        console.error('❌ Tests failed:', err.message);
        process.exit(1);
    }
}

runTests();
