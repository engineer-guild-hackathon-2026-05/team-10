import { NextResponse } from "next/server";
import { getDatasetSummary } from "@/lib/store";

export const runtime = "nodejs";

export async function GET() {
  return NextResponse.json(await getDatasetSummary());
}

