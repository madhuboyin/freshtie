'use strict';

const http = require('http');
const config = require('./utils/config');
const router = require('./utils/router');

// Import routes
const healthHandler = require('./routes/health');
const versionHandler = require('./routes/version');
const configHandler = require('./routes/config');
const eventsHandler = require('./routes/events');

// Register routes
router.get('/health', healthHandler);
router.get('/version', versionHandler);
router.get('/config/prompts', configHandler);
router.post('/events', eventsHandler);

// Root path
router.get('/', (req, res) => {
    const { sendJson } = require('./utils/response');
    sendJson(res, 200, {
        app: config.APP_NAME,
        message: 'Freshtie backend is running',
        endpoints: ['/health', '/version', '/config/prompts', '/events']
    });
});

const server = http.createServer((req, res) => router.handle(req, res));

server.listen(config.PORT, '0.0.0.0', () => {
    console.log(JSON.stringify({
        level: 'info',
        msg: 'server_started',
        app: config.APP_NAME,
        port: config.PORT,
        env: config.NODE_ENV,
        version: config.APP_VERSION,
        timestamp: new Date().toISOString()
    }));
});

function shutdown(signal) {
    console.log(JSON.stringify({
        level: 'info',
        msg: 'server_shutting_down',
        signal,
        timestamp: new Date().toISOString()
    }));

    server.close((err) => {
        if (err) {
            console.error(JSON.stringify({
                level: 'error',
                msg: 'shutdown_error',
                error: err.message,
                timestamp: new Date().toISOString()
            }));
            process.exit(1);
        }

        console.log(JSON.stringify({
            level: 'info',
            msg: 'shutdown_complete',
            timestamp: new Date().toISOString()
        }));
        process.exit(0);
    });

    setTimeout(() => {
        console.error(JSON.stringify({
            level: 'error',
            msg: 'forced_shutdown',
            timestamp: new Date().toISOString()
        }));
        process.exit(1);
    }, 10000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
