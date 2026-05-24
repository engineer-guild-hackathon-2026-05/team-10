import { NextResponse } from "next/server";
import { appendLabel } from "@/lib/store";

export const runtime = "nodejs";

export async function POST(request: Request) {
  const body = await request.json();
  const label = await appendLabel({
    sessionId: String(body.sessionId),
    label: body.label,
    startedAtSec: Math.max(0, Number(body.startedAtSec ?? 0)),
    endedAtSec: Math.max(0, Number(body.endedAtSec ?? body.startedAtSec ?? 0)),
    confidence: body.confidence
  });

  return NextResponse.json({ label });
}

