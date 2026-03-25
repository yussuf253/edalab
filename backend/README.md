# EdaLab Backend

Node.js + TypeScript + Prisma + Supabase Postgres + JWT backend scaffold for the EdaLab app.

## Stack

- Node.js
- TypeScript
- Express
- Prisma
- Supabase Postgres
- JWT
- bcrypt

## Why this fits your direction

- Works well with a Render backend plus Supabase database.
- Lets Flutter and a future web app share the same REST API.
- Keeps your business data relational from day one.
- Gives you managed Postgres, backups, and easier remote access than shared-hosting databases.

## Environment

Copy `.env.example` to `.env` and fill in:

```bash
DATABASE_URL="postgresql://postgres.PROJECT_REF:PASSWORD@aws-0-REGION.pooler.supabase.com:6543/postgres?pgbouncer=true&connection_limit=1"
DIRECT_URL="postgresql://postgres.PROJECT_REF:PASSWORD@db.PROJECT_REF.supabase.co:5432/postgres"
JWT_SECRET="replace-with-a-long-random-secret"
```

For Supabase, the database values normally come from:

- Project Settings -> Database -> Connection string
- `DATABASE_URL` should use the pooled connection string
- `DIRECT_URL` should use the direct connection string
- replace `PASSWORD`, `PROJECT_REF`, and `REGION` with your real project values

## Install

```bash
npm install
npx prisma generate
npx prisma db push
npm run db:seed
npm run dev
```

## Current API routes

### Auth

- `POST /api/auth/register`
- `POST /api/auth/login`

### Modules

- `GET /api/modules`

### Users

- `GET /api/users/:id`
- `PATCH /api/users/:id`
- `POST /api/users/:id/addresses`
- `PATCH /api/users/:id/addresses/:addressId`
- `PATCH /api/users/:id/addresses/:addressId/default`
- `DELETE /api/users/:id/addresses/:addressId`

### Orders

- `GET /api/orders/:userId`
- `POST /api/orders`

### Appointments

- `GET /api/appointments/:userId`
- `POST /api/appointments`

### Catalog

- `GET /api/catalog/products`
- `GET /api/catalog/products/:id`
- `GET /api/catalog/doctors`
- `GET /api/catalog/restaurants`
- `GET /api/catalog/hotels`
- `GET /api/catalog/ride-categories`
- `GET /api/catalog/laundry-services`

## Recommended next steps

1. Install dependencies and generate Prisma client.
2. Create your Supabase project and copy both pooled and direct Postgres URLs into `.env`.
3. Run `prisma db push` against Supabase.
4. Seed module catalogs with `npm run db:seed`.
5. Update Flutter auth flow to use `/api/auth/login` and persist JWT.
6. Protect write routes with bearer-token auth once the mobile app sends JWTs.

## Note about the Flutter app

Your current Flutter app still expects direct user payloads from `/api/users` and `/api/users/login`.
This backend keeps the core routes for users, orders, and appointments, but the recommended auth path is now:

- login via `/api/auth/login`
- receive JWT
- use bearer token on future protected endpoints

That gives you a cleaner long-term API for both app and web.
