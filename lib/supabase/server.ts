import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

import { getSupabaseAnonKey, getSupabaseUrl } from "@/lib/supabase/env";

/**
 * Client Supabase pour Server Components, Server Actions et Route Handlers.
 * Les écritures de cookies peuvent échouer dans un Server Component : le middleware assure le rafraîchissement de session.
 */
export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(getSupabaseUrl(), getSupabaseAnonKey(), {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet) {
        try {
          cookiesToSet.forEach(({ name, value, options }) => {
            cookieStore.set(name, value, options);
          });
        } catch {
          // Appel depuis un Server Component : pas d’écriture cookie possible ici.
        }
      },
    },
  });
}
