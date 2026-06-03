import { createClient } from '@supabase/supabase-js';
import { env } from '../config/env';

const supabaseUrl = env.SUPABASE_URL?.trim();
const supabaseServiceRoleKey = env.SUPABASE_SERVICE_ROLE_KEY?.trim();

if (!supabaseUrl || !supabaseServiceRoleKey) {
  console.warn('Supabase URL or service role key not configured. Supabase auth features will be disabled.');
}

export const supabaseAdmin = createClient(
  supabaseUrl || '',
  supabaseServiceRoleKey || '',
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);