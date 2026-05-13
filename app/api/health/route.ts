import { NextResponse } from "next/server";

/** Réponse légère pour supervision ou keep-alive (cron externe). */
export const dynamic = "force-dynamic";

export async function GET() {
  return NextResponse.json(
    { ok: true, service: "inventaire" },
    { status: 200, headers: { "Cache-Control": "no-store" } }
  );
}
