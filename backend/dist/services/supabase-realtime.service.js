"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sseClients = exports.supabase = void 0;
exports.subscribeToTableChanges = subscribeToTableChanges;
exports.unsubscribeFromTableChanges = unsubscribeFromTableChanges;
exports.broadcastToSSEClients = broadcastToSSEClients;
exports.addSSEClient = addSSEClient;
const supabase_js_1 = require("@supabase/supabase-js");
const env_1 = require("../config/env");
// Initialize Supabase client
const supabaseUrl = env_1.env.SUPABASE_URL?.trim();
const supabaseKey = env_1.env.SUPABASE_SERVICE_ROLE_KEY?.trim();
if (!supabaseUrl || !supabaseKey) {
    throw new Error('Supabase URL and service role key must be provided for real-time functionality');
}
exports.supabase = (0, supabase_js_1.createClient)(supabaseUrl, supabaseKey);
// Store active subscriptions
const activeSubscriptions = new Map();
// Store connected clients for SSE
exports.sseClients = new Map();
// Function to subscribe to real-time updates for a specific table
function subscribeToTableChanges(table, callback) {
    // Check if already subscribed to this table
    if (activeSubscriptions.has(table)) {
        console.log(`Already subscribed to ${table}`);
        return activeSubscriptions.get(table);
    }
    const channel = exports.supabase
        .channel(`table-changes-${table}`)
        .on('postgres_changes', { event: '*', schema: 'public', table }, (payload) => {
        console.log(`Change received for ${table}:`, payload);
        // Broadcast the change to all connected SSE clients
        broadcastToSSEClients(JSON.stringify({
            table,
            event: payload.eventType,
            data: payload.new || payload.old
        }));
        callback(payload);
    })
        .subscribe((status) => {
        if (status === 'SUBSCRIBED') {
            console.log(`Subscribed to ${table} changes`);
        }
    });
    activeSubscriptions.set(table, channel);
    return channel;
}
// Function to unsubscribe from real-time updates
function unsubscribeFromTableChanges(table) {
    const channel = activeSubscriptions.get(table);
    if (channel) {
        exports.supabase.removeChannel(channel);
        activeSubscriptions.delete(table);
        console.log(`Unsubscribed from ${table} changes`);
    }
}
// Function to broadcast messages to all connected SSE clients
function broadcastToSSEClients(message) {
    exports.sseClients.forEach((res, clientId) => {
        try {
            res.write(`data: ${message}\n\n`);
        }
        catch (error) {
            console.error(`Error sending SSE to client ${clientId}:`, error);
            exports.sseClients.delete(clientId);
        }
    });
}
// Function to add an SSE client
function addSSEClient(req, res) {
    const clientId = Date.now().toString();
    res.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Cache-Control',
    });
    exports.sseClients.set(clientId, res);
    req.on('close', () => {
        console.log(`SSE client ${clientId} disconnected`);
        exports.sseClients.delete(clientId);
    });
    req.on('error', (error) => {
        console.error(`SSE client ${clientId} error:`, error);
        exports.sseClients.delete(clientId);
    });
    console.log(`New SSE client connected: ${clientId}`);
    return clientId;
}
