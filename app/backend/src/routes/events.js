'use strict';

const config = require('../utils/config');
const { sendJson, sendError } = require('../utils/response');
const { parseJsonBody } = require('../utils/body');

module.exports = async (req, res) => {
    if (!config.EVENTS_ENABLED) {
        return sendError(res, 403, 'Event ingestion is disabled');
    }

    try {
        const payload = await parseJsonBody(req);
        
        if (!payload || (Array.isArray(payload) && payload.length === 0)) {
            return sendError(res, 400, 'Empty payload');
        }

        const events = Array.isArray(payload) ? payload : [payload];
        
        // Basic validation
        for (const event of events) {
            if (!event.eventName || !event.timestamp) {
                return sendError(res, 400, 'Invalid event shape', { event });
            }
        }

        // Structured logging for ingestion
        console.log(JSON.stringify({
            level: 'info',
            msg: 'events_ingested',
            count: events.length,
            timestamp: new Date().toISOString()
        }));

        // In a real prod environment, we would push to a queue or DB here.
        // For MVP on Raspberry Pi, we stick to structured logs.

        sendJson(res, 202, {
            status: 'accepted',
            count: events.length
        });
    } catch (err) {
        sendError(res, 400, 'Invalid JSON payload');
    }
};
