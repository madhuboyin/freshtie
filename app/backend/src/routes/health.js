'use strict';

const config = require('../utils/config');
const { sendJson } = require('../utils/response');

module.exports = (req, res) => {
    sendJson(res, 200, {
        status: 'ok',
        app: config.APP_NAME,
        env: config.NODE_ENV,
        uptimeSeconds: Math.floor(process.uptime()),
        startedAt: config.STARTED_AT,
        timestamp: new Date().toISOString()
    });
};
