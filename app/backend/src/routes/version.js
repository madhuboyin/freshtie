'use strict';

const config = require('../utils/config');
const { sendJson } = require('../utils/response');

module.exports = (req, res) => {
    sendJson(res, 200, {
        app: config.APP_NAME,
        version: config.APP_VERSION,
        env: config.NODE_ENV,
        buildSha: config.BUILD_SHA,
        timestamp: new Date().toISOString()
    });
};
