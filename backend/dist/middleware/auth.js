"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireAuth = requireAuth;
const jwt_1 = require("../utils/jwt");
function requireAuth(req, res, next) {
    const header = req.headers.authorization;
    if (!header?.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Authorization token is required.' });
    }
    const token = header.slice('Bearer '.length);
    try {
        req.auth = (0, jwt_1.verifyAccessToken)(token);
        next();
    }
    catch {
        return res.status(401).json({ error: 'Invalid or expired token.' });
    }
}
