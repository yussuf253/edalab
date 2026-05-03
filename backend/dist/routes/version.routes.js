"use strict";
// Backend Version Management Implementation Template
// This is a ready-to-use template for your backend (Node.js/Express)
Object.defineProperty(exports, "__esModule", { value: true });
/*
INSTALLATION:
npm install express prisma @prisma/client

SETUP:
1. Configure your database connection in .env
2. Run migrations: npx prisma migrate dev
3. Add these routes to your API
*/
// ============================================================================
// DATABASE SCHEMA (Prisma Schema - schema.prisma)
// ============================================================================
/*
model AppVersion {
  id                      String   @id @default(cuid())
  platform                String   // 'android', 'ios', 'both'
  currentVersion          String
  minRequiredVersion      String
  latestVersion           String
  releaseNotes            String   @db.Text
  isForceUpdateRequired    Boolean  @default(false)
  isSkippableUpdate       Boolean  @default(true)
  downloadUrl             String?
  storeUrl                String
  releasedAt              DateTime @default(now())
  isActive                Boolean  @default(true)
  createdAt               DateTime @default(now())
  updatedAt               DateTime @updatedAt

  @@index([platform, isActive])
  @@index([latestVersion])
}

model UpdateActionLog {
  id              String   @id @default(cuid())
  action          String   // 'skipped', 'updated', 'forced_update', 'update_confirmed'
  currentVersion  String
  platform        String?
  userId          String?
  timestamp       DateTime @default(now())
  deviceInfo      String?  @db.Text

  @@index([action, timestamp])
  @@index([userId])
}
*/
// ============================================================================
// EXPRESS ROUTES
// ============================================================================
const express_1 = require("express");
const client_1 = require("@prisma/client");
const router = (0, express_1.Router)();
const prisma = new client_1.PrismaClient();
// Check for app updates
router.get('/check', async (req, res) => {
    try {
        const { platform } = req.query;
        const version = await prisma.appVersion.findFirst({
            where: {
                isActive: true,
                ...(platform && {
                    OR: [
                        { platform: 'both' },
                        { platform: platform }
                    ]
                })
            },
            orderBy: {
                latestVersion: 'desc'
            }
        });
        if (!version) {
            return res.status(404).json({
                error: 'No version information available'
            });
        }
        // Return version info
        res.json({
            currentVersion: version.currentVersion,
            minRequiredVersion: version.minRequiredVersion,
            latestVersion: version.latestVersion,
            releaseNotes: version.releaseNotes,
            isForceUpdateRequired: version.isForceUpdateRequired,
            isSkippableUpdate: version.isSkippableUpdate,
            downloadUrl: version.downloadUrl || '',
            storeUrl: version.storeUrl,
            releasedAt: version.releasedAt.toISOString(),
            isActive: version.isActive
        });
    }
    catch (error) {
        console.error('Error checking version:', error);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
});
// Report user update action
router.post('/report-action', async (req, res) => {
    try {
        const { action, currentVersion, timestamp, platform, userId } = req.body;
        // Validate action
        const validActions = ['skipped', 'updated', 'forced_update', 'update_confirmed'];
        if (!validActions.includes(action)) {
            return res.status(400).json({
                error: 'Invalid action'
            });
        }
        // Log the action
        await prisma.updateActionLog.create({
            data: {
                action,
                currentVersion,
                platform: platform || null,
                userId: userId || null,
                timestamp: new Date(timestamp || Date.now())
            }
        });
        res.json({
            success: true,
            message: 'Action recorded successfully'
        });
    }
    catch (error) {
        console.error('Error reporting action:', error);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
});
// ADMIN: Get version statistics
router.get('/admin/version/stats', async (req, res) => {
    // Add authentication middleware here
    try {
        const stats = {
            totalChecks: await prisma.updateActionLog.count(),
            actionBreakdown: await prisma.updateActionLog.groupBy({
                by: ['action'],
                _count: true
            }),
            versionDistribution: await prisma.updateActionLog.groupBy({
                by: ['currentVersion'],
                _count: true,
                orderBy: {
                    _count: {
                        id: 'desc'
                    }
                }
            }),
            todayStats: {
                checks: await prisma.updateActionLog.count({
                    where: {
                        timestamp: {
                            gte: new Date(new Date().setHours(0, 0, 0, 0))
                        }
                    }
                })
            }
        };
        res.json(stats);
    }
    catch (error) {
        res.status(500).json({ error: 'Internal server error' });
    }
});
// ADMIN: Create/Update version
router.post('/admin/version/update', async (req, res) => {
    // Add authentication middleware here
    try {
        const { platform, currentVersion, minRequiredVersion, latestVersion, releaseNotes, isForceUpdateRequired, isSkippableUpdate, downloadUrl, storeUrl, isActive } = req.body;
        // Validate required fields
        if (!platform || !latestVersion || !storeUrl) {
            return res.status(400).json({
                error: 'Missing required fields'
            });
        }
        // Deactivate other versions for this platform
        await prisma.appVersion.updateMany({
            where: {
                platform: { in: ['both', platform] },
                NOT: { id: req.body.id }
            },
            data: { isActive: false }
        });
        // Create or update version
        let version;
        if (req.body.id) {
            version = await prisma.appVersion.update({
                where: { id: req.body.id },
                data: {
                    platform,
                    currentVersion: currentVersion || '1.0.0',
                    minRequiredVersion: minRequiredVersion || '1.0.0',
                    latestVersion,
                    releaseNotes,
                    isForceUpdateRequired: isForceUpdateRequired ?? false,
                    isSkippableUpdate: isSkippableUpdate ?? true,
                    downloadUrl,
                    storeUrl,
                    isActive: isActive ?? true
                }
            });
        }
        else {
            version = await prisma.appVersion.create({
                data: {
                    platform,
                    currentVersion: currentVersion || '1.0.0',
                    minRequiredVersion: minRequiredVersion || '1.0.0',
                    latestVersion,
                    releaseNotes,
                    isForceUpdateRequired: isForceUpdateRequired ?? false,
                    isSkippableUpdate: isSkippableUpdate ?? true,
                    downloadUrl,
                    storeUrl,
                    isActive: isActive ?? true
                }
            });
        }
        res.json({
            success: true,
            data: {
                id: version.id,
                platform: version.platform,
                latestVersion: version.latestVersion,
                updatedAt: version.updatedAt
            }
        });
    }
    catch (error) {
        console.error('Error updating version:', error);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
});
// ADMIN: Get all versions
router.get('/admin/versions', async (req, res) => {
    // Add authentication middleware here
    try {
        const versions = await prisma.appVersion.findMany({
            orderBy: { createdAt: 'desc' }
        });
        res.json(versions);
    }
    catch (error) {
        res.status(500).json({ error: 'Internal server error' });
    }
});
exports.default = router;
// ============================================================================
// MAIN APP INTEGRATION (main.ts)
// ============================================================================
/*
import express from 'express';
import versionRoutes from './routes/version';

const app = express();

app.use(express.json());
app.use('/api', versionRoutes);

const PORT = process.env.PORT || 5050;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
*/
// ============================================================================
// SEEDING INITIAL DATA (seed.ts)
// ============================================================================
/*
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // Create initial version
  const version = await prisma.appVersion.create({
    data: {
      platform: 'android',
      currentVersion: '1.0.0',
      minRequiredVersion: '1.0.0',
      latestVersion: '1.0.0',
      releaseNotes: 'Initial release',
      isForceUpdateRequired: false,
      isSkippableUpdate: true,
      storeUrl: 'https://play.google.com/store/apps/details?id=com.edalab',
      isActive: true
    }
  });

  console.log('Seeded version:', version);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
*/
// ============================================================================
// TESTING WITH CURL
// ============================================================================
/*
# Check for updates
curl -X GET http://localhost:5050/api/version/check

# Check for Android updates
curl -X GET "http://localhost:5050/api/version/check?platform=android"

# Report user action
curl -X POST http://localhost:5050/api/version/report-action \
  -H "Content-Type: application/json" \
  -d '{
    "action": "updated",
    "currentVersion": "1.0.0",
    "timestamp": "2026-04-28T10:00:00Z"
  }'

# Create new version (admin)
curl -X POST http://localhost:5050/api/admin/version/update \
  -H "Content-Type: application/json" \
  -d '{
    "platform": "android",
    "currentVersion": "1.0.0",
    "minRequiredVersion": "1.0.0",
    "latestVersion": "1.2.5",
    "releaseNotes": "Performance improvements",
    "isForceUpdateRequired": false,
    "isSkippableUpdate": true,
    "storeUrl": "https://play.google.com/store/apps/details?id=com.edalab"
  }'

# Get statistics (admin)
curl -X GET http://localhost:5050/api/admin/version/stats
*/
