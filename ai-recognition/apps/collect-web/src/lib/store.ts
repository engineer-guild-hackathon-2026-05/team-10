import { randomUUID } from "node:crypto";
import * as fs from "node:fs/promises";
import path from "node:path";
import { createTrainingExamplesFromSession } from "@howtune/ml/features";
import type {
  CollectionLabel,
  LabelEvent,
  MotionSample,
  TrainingExample
} from "@howtune/ml/schema";

export type SessionRecord = {
  id: string;
  userId: string;
  songId: string;
  startedAt: string;
  endedAt?: string;
  device: {
    userAgent: string;
    platform?: string;
    screenWidth?: number;
    screenHeight?: number;
  };
  listeningContext: {
    phonePosition: "hand" | "table" | "pocket";
    dominantHand?: "right" | "left" | "unknown";
    usualMovement: "active" | "still" | "depends";
  };
};

export type MotionSampleBatch = {
  sessionId: string;
  chunkIndex: number;
  samples: MotionSample[];
};

type StoreShape = {
  sessions: SessionRecord[];
  motionBatches: MotionSampleBatch[];
  labels: LabelEvent[];
};

const STORE_DIR = path.join(process.cwd(), ".data");
const STORE_PATH = path.join(STORE_DIR, "collection-store.json");

export async function createSession(input: {
  songId: string;
  userAgent: string;
  phonePosition: SessionRecord["listeningContext"]["phonePosition"];
  dominantHand?: SessionRecord["listeningContext"]["dominantHand"];
  usualMovement: SessionRecord["listeningContext"]["usualMovement"];
  screenWidth?: number;
  screenHeight?: number;
}): Promise<SessionRecord> {
  const store = await readStore();
  const session: SessionRecord = {
    id: `session_${randomUUID().slice(0, 8)}`,
    userId: "anonymous",
    songId: input.songId,
    startedAt: new Date().toISOString(),
    device: {
      userAgent: input.userAgent,
      screenWidth: input.screenWidth,
      screenHeight: input.screenHeight
    },
    listeningContext: {
      phonePosition: input.phonePosition,
      dominantHand: input.dominantHand,
      usualMovement: input.usualMovement
    }
  };

  store.sessions.push(session);
  await writeStore(store);
  return session;
}

export async function getSessionBundle(sessionId: string): Promise<{
  session?: SessionRecord;
  samples: MotionSample[];
  labels: LabelEvent[];
}> {
  const store = await readStore();
  return {
    session: store.sessions.find((session) => session.id === sessionId),
    samples: store.motionBatches
      .filter((batch) => batch.sessionId === sessionId)
      .toSorted((a, b) => a.chunkIndex - b.chunkIndex)
      .flatMap((batch) => batch.samples),
    labels: store.labels
      .filter((label) => label.sessionId === sessionId)
      .toSorted((a, b) => a.startedAtSec - b.startedAtSec)
  };
}

export async function endSession(sessionId: string): Promise<void> {
  const store = await readStore();
  const session = store.sessions.find((item) => item.id === sessionId);
  if (session && !session.endedAt) {
    session.endedAt = new Date().toISOString();
  }
  await writeStore(store);
}

export async function appendMotionBatch(batch: MotionSampleBatch): Promise<void> {
  const store = await readStore();
  const existingIndex = store.motionBatches.findIndex(
    (item) => item.sessionId === batch.sessionId && item.chunkIndex === batch.chunkIndex
  );

  if (existingIndex >= 0) {
    store.motionBatches[existingIndex] = batch;
  } else {
    store.motionBatches.push(batch);
  }

  await writeStore(store);
}

export async function appendLabel(input: {
  sessionId: string;
  label: CollectionLabel;
  startedAtSec: number;
  endedAtSec: number;
  confidence?: 1 | 2 | 3;
}): Promise<LabelEvent> {
  const store = await readStore();
  const labelEvent: LabelEvent = {
    id: `label_${randomUUID().slice(0, 8)}`,
    sessionId: input.sessionId,
    label: input.label,
    startedAtSec: input.startedAtSec,
    endedAtSec: input.endedAtSec,
    source: "realtime_button",
    confidence: input.confidence
  };

  store.labels.push(labelEvent);
  await writeStore(store);
  return labelEvent;
}

export async function replaceSessionLabels(sessionId: string, labels: LabelEvent[]): Promise<void> {
  const store = await readStore();
  store.labels = [
    ...store.labels.filter((label) => label.sessionId !== sessionId),
    ...labels.map((label) => ({
      ...label,
      sessionId,
      source: "review_edit" as const
    }))
  ];
  await writeStore(store);
}

export async function getDatasetSummary(): Promise<{
  sessions: Array<SessionRecord & { sampleCount: number; labelCount: number; durationSec: number }>;
  totals: {
    sessions: number;
    samples: number;
    labels: number;
    noiseRate: number;
  };
  labelCounts: Record<string, number>;
}> {
  const store = await readStore();
  const labelCounts = store.labels.reduce<Record<string, number>>((counts, label) => {
    counts[label.label] = (counts[label.label] ?? 0) + 1;
    return counts;
  }, {});
  const sessions = store.sessions.map((session) => {
    const samples = store.motionBatches
      .filter((batch) => batch.sessionId === session.id)
      .flatMap((batch) => batch.samples);
    const labels = store.labels.filter((label) => label.sessionId === session.id);
    return {
      ...session,
      sampleCount: samples.length,
      labelCount: labels.length,
      durationSec: samples.at(-1)?.t ?? 0
    };
  });
  const totalLabels = store.labels.length;
  const noiseLabels = store.labels.filter(
    (label) => label.label === "noise" || label.label === "phone_on_table"
  ).length;

  return {
    sessions,
    totals: {
      sessions: store.sessions.length,
      samples: store.motionBatches.reduce((sum, batch) => sum + batch.samples.length, 0),
      labels: totalLabels,
      noiseRate: totalLabels === 0 ? 0 : noiseLabels / totalLabels
    },
    labelCounts
  };
}

export async function exportTrainingExamples(sessionId?: string): Promise<TrainingExample[]> {
  const store = await readStore();
  const sessions = sessionId
    ? store.sessions.filter((session) => session.id === sessionId)
    : store.sessions;

  return sessions.flatMap((session) => {
    const samples = store.motionBatches
      .filter((batch) => batch.sessionId === session.id)
      .toSorted((a, b) => a.chunkIndex - b.chunkIndex)
      .flatMap((batch) => batch.samples);
    const labels = store.labels.filter((label) => label.sessionId === session.id);

    return createTrainingExamplesFromSession({
      sessionId: session.id,
      songId: session.songId,
      samples,
      labels,
      meta: {
        userAgent: session.device.userAgent,
        phonePosition: session.listeningContext.phonePosition,
        dominantHand: session.listeningContext.dominantHand,
        usualMovement: session.listeningContext.usualMovement
      }
    });
  });
}

async function readStore(): Promise<StoreShape> {
  try {
    const raw = await fs.readFile(STORE_PATH, "utf8");
    return JSON.parse(raw) as StoreShape;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") {
      throw error;
    }

    return { sessions: [], motionBatches: [], labels: [] };
  }
}

async function writeStore(store: StoreShape): Promise<void> {
  await fs.mkdir(STORE_DIR, { recursive: true });
  await fs.writeFile(STORE_PATH, `${JSON.stringify(store, null, 2)}\n`);
}
