import { NextFunction, Request, Response } from 'express';
import { Prisma } from '@prisma/client';
import { ZodError } from 'zod';

export function notFoundHandler(_req: Request, res: Response) {
  res.status(404).json({ error: 'Route not found.' });
}

export function errorHandler(
  error: unknown,
  req: Request,
  res: Response,
  _next: NextFunction,
) {
  const message = error instanceof Error ? error.message : 'Internal server error.';
  const stack = error instanceof Error ? error.stack : undefined;

  console.error('[API ERROR]', {
    method: req.method,
    path: req.originalUrl,
    message,
    stack,
  });

  if (error instanceof ZodError) {
    return res.status(400).json({
      error: 'Validation failed.',
      details: error.flatten(),
    });
  }

  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    return res.status(400).json({
      error: error.message,
      code: error.code,
    });
  }

  return res.status(500).json({ error: message });
}
