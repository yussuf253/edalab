"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.supabase = void 0;
exports.initializeWebSocketServer = initializeWebSocketServer;
exports.broadcastToClients = broadcastToClients;
exports.subscribeToTableChanges = subscribeToTableChanges;
exports.unsubscribeFromTableChanges = unsubscribeFromTableChanges;
const supabase_js_1 = require("@supabase/supabase-js");
const env_1 = require("../config/env");
const ws_1 = __importStar(require("ws"));
// Initialize Supabase client
const supabaseUrl = env_1.env.SUPABASE_URL?.trim();
const supabaseKey = env_1.env.SUPABASE_SERVICE_ROLE_KEY?.trim();
if (!supabaseUrl || !supabaseKey) {
    throw new Error('Supabase URL and service role key must be provided for real-time functionality');
}
exports.supabase = (0, supabase_js_1.createClient)(supabaseUrl, supabaseKey);
// WebSocket server for real-time updates
let wss = null;
function initializeWebSocketServer(server) {
    wss = new ws_1.WebSocketServer({ server });
    wss.on('connection', (ws) => {
        console.log('New WebSocket client connected');
        ws.on('close', () => {
            console.log('WebSocket client disconnected');
        });
    });
}
// Function to broadcast messages to all connected WebSocket clients
function broadcastToClients(message) {
    if (wss) {
        wss.clients.forEach((client) => {
            if (client.readyState === ws_1.default.OPEN) {
                client.send(message);
            }
        });
    }
}
// Function to subscribe to real-time updates for a specific table
function subscribeToTableChanges(table, callback) {
    const channel = exports.supabase
        .channel(`table-changes-${table}`)
        .on('postgres_changes', { event: '*', schema: 'public', table }, (payload) => {
        console.log(`Change received for ${table}:`, payload);
        // Broadcast the change to all WebSocket clients
        broadcastToClients(JSON.stringify({
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
    return channel;
}
// Function to unsubscribe from real-time updates
function unsubscribeFromTableChanges(channel) {
    exports.supabase.removeChannel(channel);
    console.log('Unsubscribed from table changes');
}
