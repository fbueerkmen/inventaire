import { createBrowserClient } from "@supabase/ssr";

import { getSupabaseAnonKey, getSupabaseUrl } from "@/lib/supabase/env";

/**
 * Client Supabase pour Composants Client et code navigateur.
 * Singleton géré par `@supabase/ssr`.
 */
export function createClient() {
  return createBrowserClient(getSupabaseUrl(), getSupabaseAnonKey());
}
