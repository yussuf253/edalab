"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.notFoundHandler = notFoundHandler;
exports.errorHandler = errorHandler;
const client_1 = require("@prisma/client");
const zod_1 = require("zod");
function notFoundHandler(_req, res) {
    res.status(404).json({ error: 'Route not found.' });
}
function errorHandler(error, _req, res, _next) {
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
    const message = error instanceof Error ? error.message : 'Internal server error.';
    return res.status(500).json({ error: message });
}
