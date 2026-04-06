'use strict';

/**
 * Helper to parse JSON body from request.
 */
function parseJsonBody(req) {
    return new Promise((resolve, reject) => {
        let body = '';
        req.on('data', chunk => { body += chunk.toString(); });
        req.on('end', () => {
            try {
                if (!body) return resolve(null);
                resolve(JSON.parse(body));
            } catch (err) {
                reject(new Error('Invalid JSON'));
            }
        });
    });
}

module.exports = {
    parseJsonBody
};
