"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.notFoundHandler = notFoundHandler;
exports.errorHandler = errorHandler;
const client_1 = require("@prisma/client");
const zod_1 = require("zod");
function notFoundHandler(_req, res) {
    res.status(404).json({ error: 'Route not found.' });
}
function errorHandler(error, req, res, _next) {
    const message = error instanceof Error ? error.message : 'Internal server error.';
    const stack = error instanceof Error ? error.stack : undefined;
    console.error('[API ERROR]', {
        method: req.method,
        path: req.originalUrl,
        message,
        stack,
    });
    if (error instanceof zod_1.ZodError) {
        return res.status(400).json({
            error: 'Validation failed.',
            details: error.flatten(),
        });
    }
    if (error instanceof client_1.Prisma.PrismaClientKnownRequestError) {
        return res.status(400).json({
            error: error.message,
            code: error.code,
        });
    }
    return res.status(500).json({ error: message });
}
