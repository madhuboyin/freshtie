'use strict';

/**
 * Standard utility for sending JSON responses.
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
 * Standard error responses.
 */
function sendError(res, statusCode, message, details = null) {
    const payload = {
        error: true,
        message: message
    };
    if (details) payload.details = details;
    sendJson(res, statusCode, payload);
}

module.exports = {
    sendJson,
    sendError
};
