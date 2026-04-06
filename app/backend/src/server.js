'use strict';

const http = require('http');

const PORT = Number(process.env.PORT || 3000);
const NODE_ENV = process.env.NODE_ENV || 'development';
const APP_NAME = process.env.APP_NAME || 'freshtie';
const STARTED_AT = new Date().toISOString();

/**
 * Send a JSON response with standard headers.
 * @param {http.ServerResponse} res
 * @param {number} statusCode
 * @param {object} payload
 */
function sendJson(res, statusCode, payload) {
    const body = JSON.stringify(payload);

    res.writeHead(statusCode, {
        'Content-Type': 'application/json; charset=utf-8',
        'Content-Length': Buffer.byteLength(body),
        'Cache-Control': 'no-store'
    });

    res.end(body);
}

/**
 * Basic request router.
 * @param {http.IncomingMessage} req
 * @param {http.ServerResponse} res
 */
function requestHandler(req, res) {
    const method = req.method || 'GET';
    const url = req.url || '/';

    if (method === 'GET' && url === '/health') {
        return sendJson(res, 200, {
            status: 'ok',
            app: APP_NAME,
            env: NODE_ENV,
            uptimeSeconds: Math.floor(process.uptime()),
            startedAt: STARTED_AT,
            timestamp: new Date().toISOString()
        });
    }

    if (method === 'GET' && url === '/') {
        return sendJson(res, 200, {
            app: APP_NAME,
            message: 'Freshtie backend is running',
            health: '/health'
        });
    }

    return sendJson(res, 404, {
        error: 'Not Found',
        path: url
    });
}

const server = http.createServer(requestHandler);

server.listen(PORT, '0.0.0.0', () => {
    console.log(`[${APP_NAME}] listening on port ${PORT} in ${NODE_ENV}`);
});

function shutdown(signal) {
    console.log(`[${APP_NAME}] received ${signal}, shutting down...`);

    server.close((err) => {
        if (err) {
            console.error(`[${APP_NAME}] shutdown error`, err);
            process.exit(1);
        }

        console.log(`[${APP_NAME}] shutdown complete`);
        process.exit(0);
    });

    setTimeout(() => {
        console.error(`[${APP_NAME}] forced shutdown after timeout`);
        process.exit(1);
    }, 10000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));