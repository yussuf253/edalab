import { NextFunction, Request, Response } from 'express';
import { verifyAccessToken } from '../utils/jwt';
import { prisma } from '../db';

export async function requireAuth(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization;

  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authorization token is required.' });
  }

  const token = header.slice('Bearer '.length);

  try {
    const payload = verifyAccessToken(token);
    
    // Check if user/pro account is banned
    if (payload.accountType === 'pro') {
      const account = await prisma.proAccount.findUnique({
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
    } else {
      const user = await prisma.user.findUnique({
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
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token.' });
  }
}
