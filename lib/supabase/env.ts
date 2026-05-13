function readPublicEnv(name: "NEXT_PUBLIC_SUPABASE_URL" | "NEXT_PUBLIC_SUPABASE_ANON_KEY"): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(
      `Variable d'environnement manquante : ${name}. Copier .env.local.example vers .env.local et renseigner les clés Supabase.`
    );
  }
  return value;
}

export function getSupabaseUrl(): string {
  return readPublicEnv("NEXT_PUBLIC_SUPABASE_URL");
}

export function getSupabaseAnonKey(): string {
  return readPublicEnv("NEXT_PUBLIC_SUPABASE_ANON_KEY");
}
