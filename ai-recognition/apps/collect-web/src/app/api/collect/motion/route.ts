import { NextResponse } from "next/server";
import { appendMotionBatch } from "@/lib/store";

export const runtime = "nodejs";

export async function POST(request: Request) {
  const body = await request.json();

  await appendMotionBatch({
    sessionId: String(body.sessionId),
    chunkIndex: Number(body.chunkIndex ?? 0),
    samples: Array.isArray(body.samples) ? body.samples : []
  });

  return NextResponse.json({ ok: true });
}

