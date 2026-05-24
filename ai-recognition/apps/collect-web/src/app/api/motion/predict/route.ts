import { NextResponse } from "next/server";
import { predictMotionReaction } from "@howtune/ml/predict";

export const runtime = "nodejs";

export async function POST(request: Request) {
  const body = await request.json();
  const response = await predictMotionReaction(
    {
      sessionId: String(body.sessionId ?? "session_preview"),
      songId: String(body.songId ?? "song_preview"),
      samples: Array.isArray(body.samples) ? body.samples : []
    },
    { allowHeuristicFallback: true }
  );

  return NextResponse.json(response);
}

