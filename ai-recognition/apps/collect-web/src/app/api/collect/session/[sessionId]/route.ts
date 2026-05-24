import { NextResponse } from "next/server";
import { endSession, getSessionBundle } from "@/lib/store";

export const runtime = "nodejs";

type RouteContext = {
  params: Promise<{ sessionId: string }>;
};

export async function GET(_request: Request, context: RouteContext) {
  const { sessionId } = await context.params;
  const bundle = await getSessionBundle(sessionId);

  if (!bundle.session) {
    return NextResponse.json({ error: "Session not found" }, { status: 404 });
  }

  return NextResponse.json(bundle);
}

export async function PATCH(_request: Request, context: RouteContext) {
  const { sessionId } = await context.params;
  await endSession(sessionId);
  return NextResponse.json({ ok: true });
}

