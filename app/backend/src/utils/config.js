'use strict';

const pkg = require('../../package.json');

const config = {
    APP_NAME: process.env.APP_NAME || 'freshtie',
    APP_VERSION: process.env.APP_VERSION || pkg.version || '0.1.0',
    NODE_ENV: process.env.NODE_ENV || 'development',
    PORT: Number(process.env.PORT || 3000),
    LOG_LEVEL: process.env.LOG_LEVEL || 'info',
    BUILD_SHA: process.env.BUILD_SHA || 'unknown',
    STARTED_AT: new Date().toISOString(),
    
    // Feature flags
    EVENTS_ENABLED: process.env.EVENTS_ENABLED !== 'false',
    PROMPT_CONFIG_VERSION: process.env.PROMPT_CONFIG_VERSION || '1.0.0'
};

module.exports = config;
