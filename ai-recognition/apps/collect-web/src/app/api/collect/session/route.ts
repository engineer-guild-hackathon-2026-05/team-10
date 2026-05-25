import { NextResponse } from "next/server";
import { createSession } from "@/lib/store";

export const runtime = "nodejs";

export async function POST(request: Request) {
  const body = await request.json();
  const session = await createSession({
    songId: String(body.songId ?? "groove-demo"),
    userAgent: request.headers.get("user-agent") ?? "unknown",
    phonePosition: body.phonePosition ?? "hand",
    dominantHand: body.dominantHand ?? "unknown",
    usualMovement: body.usualMovement ?? "depends",
    screenWidth: Number(body.screenWidth ?? 0),
    screenHeight: Number(body.screenHeight ?? 0)
  });

  return NextResponse.json({ sessionId: session.id, session });
}

