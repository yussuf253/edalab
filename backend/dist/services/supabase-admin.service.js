"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.supabaseAdmin = void 0;
const supabase_js_1 = require("@supabase/supabase-js");
const env_1 = require("../config/env");
const supabaseUrl = env_1.env.SUPABASE_URL?.trim();
const supabaseServiceRoleKey = env_1.env.SUPABASE_SERVICE_ROLE_KEY?.trim();
if (!supabaseUrl || !supabaseServiceRoleKey) {
    console.warn('Supabase URL or service role key not configured. Supabase auth features will be disabled.');
}
exports.supabaseAdmin = (0, supabase_js_1.createClient)(supabaseUrl || '', supabaseServiceRoleKey || '', {
    auth: {
        autoRefreshToken: false,
        persistSession: false,
    },
});
