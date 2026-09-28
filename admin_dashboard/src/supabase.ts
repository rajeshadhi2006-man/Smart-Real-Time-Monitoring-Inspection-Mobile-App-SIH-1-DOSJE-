import { createClient } from '@supabase/supabase-js';

const supabaseUrl =
  import.meta.env.VITE_SUPABASE_URL ||
  'https://ctmkpwwbdexwkakuqpat.supabase.co';

const supabaseAnonKey =
  import.meta.env.VITE_SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0bWtwd3diZGV4d2tha3VxcGF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg2MDk4MDAsImV4cCI6MjEwNDE4NTgwMH0.ilxOvgsxXQoD3Rh6pZgmfiEMET5u3RtS-B0W_kOEhLU';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
