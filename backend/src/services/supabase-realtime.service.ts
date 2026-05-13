import { createClient } from '@supabase/supabase-js';
import { env } from '../config/env';
import WebSocket, { WebSocketServer } from 'ws';

// Initialize Supabase client
const supabaseUrl = env.SUPABASE_URL?.trim();
const supabaseKey = env.SUPABASE_SERVICE_ROLE_KEY?.trim();

if (!supabaseUrl || !supabaseKey) {
  throw new Error('Supabase URL and service role key must be provided for real-time functionality');
}

export const supabase = createClient(supabaseUrl, supabaseKey);

// WebSocket server for real-time updates
let wss: WebSocketServer | null = null;

export function initializeWebSocketServer(server: any) {
  wss = new WebSocketServer({ server });
  
  wss.on('connection', (ws: WebSocket) => {
    console.log('New WebSocket client connected');
    
    ws.on('close', () => {
      console.log('WebSocket client disconnected');
    });
  });
}

// Function to broadcast messages to all connected WebSocket clients
export function broadcastToClients(message: string) {
  if (wss) {
    wss.clients.forEach((client: WebSocket) => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(message);
      }
    });
  }
}

// Function to subscribe to real-time updates for a specific table
export function subscribeToTableChanges(table: string, callback: (payload: any) => void) {
  const channel = supabase
    .channel(`table-changes-${table}`)
    .on(
      'postgres_changes',
      { event: '*', schema: 'public', table },
      (payload) => {
        console.log(`Change received for ${table}:`, payload);
        // Broadcast the change to all WebSocket clients
        broadcastToClients(JSON.stringify({
          table,
          event: payload.eventType,
          data: payload.new || payload.old
        }));
        callback(payload);
      }
    )
    .subscribe((status) => {
      if (status === 'SUBSCRIBED') {
        console.log(`Subscribed to ${table} changes`);
      }
    });

  return channel;
}

// Function to unsubscribe from real-time updates
export function unsubscribeFromTableChanges(channel: any) {
  supabase.removeChannel(channel);
  console.log('Unsubscribed from table changes');
}