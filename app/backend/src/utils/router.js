'use strict';

const { sendError } = require('./response');

class Router {
    constructor() {
        this.routes = {
            GET: {},
            POST: {},
            PUT: {},
            DELETE: {}
        };
    }

    get(path, handler) { this.routes.GET[path] = handler; }
    post(path, handler) { this.routes.POST[path] = handler; }

    async handle(req, res) {
        const method = req.method;
        const url = new URL(req.url, `http://${req.headers.host}`);
        const path = url.pathname;

        const handler = this.routes[method] && this.routes[method][path];

        if (handler) {
            try {
                await handler(req, res);
            } catch (err) {
                console.error(`[Router] Error handling ${method} ${path}:`, err);
                sendError(res, 500, 'Internal Server Error');
            }
        } else {
            sendError(res, 404, 'Not Found', { path });
        }
    }
}

module.exports = new Router();
