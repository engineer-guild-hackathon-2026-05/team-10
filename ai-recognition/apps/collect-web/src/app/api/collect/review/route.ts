import { NextResponse } from "next/server";
import { replaceSessionLabels } from "@/lib/store";

export const runtime = "nodejs";

export async function POST(request: Request) {
  const body = await request.json();
  await replaceSessionLabels(String(body.sessionId), Array.isArray(body.labels) ? body.labels : []);
  return NextResponse.json({ ok: true });
}

