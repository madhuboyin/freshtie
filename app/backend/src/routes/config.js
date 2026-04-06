'use strict';

const config = require('../utils/config');
const { sendJson } = require('../utils/response');

module.exports = (req, res) => {
    sendJson(res, 200, {
        promptConfig: {
            version: config.PROMPT_CONFIG_VERSION,
            enabledCategories: [
                'Social', 'Professional', 'Future', 'Shared History', 'Life Updates'
            ],
            refreshEnabled: true
        },
        featureFlags: {
            eventsEnabled: config.EVENTS_ENABLED,
            voiceCaptureEnabled: true
        }
    });
};
