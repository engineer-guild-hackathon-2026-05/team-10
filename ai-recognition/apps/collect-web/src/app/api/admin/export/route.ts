import { NextResponse } from "next/server";
import { exportTrainingExamples } from "@/lib/store";

export const runtime = "nodejs";

export async function GET(request: Request) {
  const url = new URL(request.url);
  const format = url.searchParams.get("format") ?? "jsonl";
  const sessionId = url.searchParams.get("sessionId") ?? undefined;
  const examples = await exportTrainingExamples(sessionId);

  if (format === "json") {
    return NextResponse.json({ examples });
  }

  const body = examples.map((example) => JSON.stringify(example)).join("\n");
  return new NextResponse(`${body}${body ? "\n" : ""}`, {
    headers: {
      "content-type": "application/x-ndjson; charset=utf-8",
      "content-disposition": "attachment; filename=training_examples.jsonl"
    }
  });
}

