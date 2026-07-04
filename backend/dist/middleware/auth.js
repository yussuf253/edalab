"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireAuth = requireAuth;
const jwt_1 = require("../utils/jwt");
const db_1 = require("../db");
async function requireAuth(req, res, next) {
    const header = req.headers.authorization;
    if (!header?.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Authorization token is required.' });
    }
    const token = header.slice('Bearer '.length);
    try {
        const payload = (0, jwt_1.verifyAccessToken)(token);
        // Check if user/pro account is banned
        if (payload.accountType === 'pro') {
            const account = await db_1.prisma.proAccount.findUnique({
                where: { id: payload.userId },
                select: { banned: true, banReason: true },
            });
            if (account?.banned) {
                return res.status(403).json({
                    error: 'Your account has been suspended.',
                    banReason: account.banReason,
                    banned: true,
                });
            }
        }
        else {
            const user = await db_1.prisma.user.findUnique({
                where: { id: payload.userId },
                select: { banned: true, banReason: true },
            });
            if (user?.banned) {
                return res.status(403).json({
                    error: 'Your account has been suspended.',
                    banReason: user.banReason,
                    banned: true,
                });
            }
        }
        req.auth = payload;
        next();
    }
    catch {
        return res.status(401).json({ error: 'Invalid or expired token.' });
    }
}
