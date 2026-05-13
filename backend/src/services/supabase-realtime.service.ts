import { createClient } from '@supabase/supabase-js';
import { env } from '../config/env';
import { Request, Response } from 'express';

// Initialize Supabase client
const supabaseUrl = env.SUPABASE_URL?.trim();
const supabaseKey = env.SUPABASE_SERVICE_ROLE_KEY?.trim();

if (!supabaseUrl || !supabaseKey) {
  throw new Error('Supabase URL and service role key must be provided for real-time functionality');
}

export const supabase = createClient(supabaseUrl, supabaseKey);

// Store active subscriptions
const activeSubscriptions: Map<string, any> = new Map();

// Store connected clients for SSE
export const sseClients: Map<string, Response> = new Map();

// Function to subscribe to real-time updates for a specific table
export function subscribeToTableChanges(table: string, callback: (payload: any) => void) {
  // Check if already subscribed to this table
  if (activeSubscriptions.has(table)) {
    console.log(`Already subscribed to ${table}`);
    return activeSubscriptions.get(table);
  }

  const channel = supabase
    .channel(`table-changes-${table}`)
    .on(
      'postgres_changes',
      { event: '*', schema: 'public', table },
      (payload) => {
        console.log(`Change received for ${table}:`, payload);
        // Broadcast the change to all connected SSE clients
        broadcastToSSEClients(JSON.stringify({
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

  activeSubscriptions.set(table, channel);
  return channel;
}

// Function to unsubscribe from real-time updates
export function unsubscribeFromTableChanges(table: string) {
  const channel = activeSubscriptions.get(table);
  if (channel) {
    supabase.removeChannel(channel);
    activeSubscriptions.delete(table);
    console.log(`Unsubscribed from ${table} changes`);
  }
}

// Function to broadcast messages to all connected SSE clients
export function broadcastToSSEClients(message: string) {
  sseClients.forEach((res, clientId) => {
    try {
      res.write(`data: ${message}\n\n`);
    } catch (error) {
      console.error(`Error sending SSE to client ${clientId}:`, error);
      sseClients.delete(clientId);
    }
  });
}

// Function to add an SSE client
export function addSSEClient(req: Request, res: Response) {
  const clientId = Date.now().toString();
  
  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Cache-Control',
  });
  
  sseClients.set(clientId, res);
  
  req.on('close', () => {
    console.log(`SSE client ${clientId} disconnected`);
    sseClients.delete(clientId);
  });
  
  req.on('error', (error) => {
    console.error(`SSE client ${clientId} error:`, error);
    sseClients.delete(clientId);
  });
  
  console.log(`New SSE client connected: ${clientId}`);
  
  return clientId;
}
