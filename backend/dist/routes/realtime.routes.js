"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const supabase_realtime_service_1 = require("../services/supabase-realtime.service");
const router = (0, express_1.Router)();
// Store active subscriptions
const activeSubscriptions = new Map();
// Subscribe to real-time updates for a table
router.post('/subscribe', (req, res) => {
    const { table } = req.body;
    if (!table) {
        return res.status(400).json({ error: 'Table name is required' });
    }
    // Check if already subscribed to this table
    if (activeSubscriptions.has(table)) {
        return res.status(200).json({ message: `Already subscribed to ${table}` });
    }
    try {
        const channel = (0, supabase_realtime_service_1.subscribeToTableChanges)(table, (payload) => {
            // The broadcast is handled in the subscribeToTableChanges function
            console.log(`Change processed for ${table}`);
        });
        activeSubscriptions.set(table, channel);
        res.status(200).json({ message: `Subscribed to ${table} changes` });
    }
    catch (error) {
        console.error('Error subscribing to table changes:', error);
        res.status(500).json({ error: 'Failed to subscribe to table changes' });
    }
});
// Unsubscribe from real-time updates
router.post('/unsubscribe', (req, res) => {
    const { table } = req.body;
    if (!table) {
        return res.status(400).json({ error: 'Table name is required' });
    }
    const channel = activeSubscriptions.get(table);
    if (channel) {
        (0, supabase_realtime_service_1.unsubscribeFromTableChanges)(channel);
        activeSubscriptions.delete(table);
        res.status(200).json({ message: `Unsubscribed from ${table} changes` });
    }
    else {
        res.status(404).json({ error: `No active subscription for ${table}` });
    }
});
// Get list of active subscriptions
router.get('/subscriptions', (req, res) => {
    const subscriptions = Array.from(activeSubscriptions.keys());
    res.status(200).json({ subscriptions });
});
exports.default = router;
