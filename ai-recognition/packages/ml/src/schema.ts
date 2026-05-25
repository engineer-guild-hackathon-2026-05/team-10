export const LISTENING_LABELS = [
  "groove",
  "chill",
  "neutral"
] as const;

export const COLLECTION_LABELS = [
  ...LISTENING_LABELS
] as const;

export const FEATURE_KEYS = [
  "meanMagnitude",
  "stdMagnitude",
  "meanDelta",
  "maxDelta",
  "energy",
  "peakCount",
  "rhythmRegularity",
  "stillness",
  "previousEnergyDiff",
  "windowDurationSec"
] as const;

export type ListeningLabel = (typeof LISTENING_LABELS)[number];
export type CollectionLabel = (typeof COLLECTION_LABELS)[number];
export type FeatureKey = (typeof FEATURE_KEYS)[number];

export type MotionSample = {
  t: number;
  ax: number;
  ay: number;
  az: number;
  gx?: number;
  gy?: number;
  gz?: number;
  source?: "headphone_motion" | "device_motion" | "accelerometer";
  pitch?: number;
  roll?: number;
  yaw?: number;
};

export type MotionFeatures = Record<FeatureKey, number>;

export type ListeningStateScores = Record<ListeningLabel, number>;

export type ListeningLabels = Record<ListeningLabel, 0 | 1>;

export type TrainingExample = {
  id: string;
  sessionId: string;
  songId: string;
  windowStart: number;
  windowEnd: number;
  features: number[];
  labels: ListeningLabels;
  meta: {
    device?: string;
    userAgent?: string;
    songSection?: string;
    bpm?: number;
    phonePosition?: "hand" | "table" | "pocket";
    dominantHand?: "right" | "left" | "unknown";
    usualMovement?: "active" | "still" | "depends";
    motionSource?: "headphone_motion" | "device_motion" | "accelerometer";
  };
};

export type LabelEvent = {
  id: string;
  sessionId: string;
  label: CollectionLabel;
  startedAtSec: number;
  endedAtSec: number;
  source: "realtime_button" | "review_edit";
  confidence?: 1 | 2 | 3;
};

export type PredictionWindow = {
  start: number;
  end: number;
  scores: ListeningStateScores;
  topLabels: ListeningLabel[];
};

export type ReactionCandidate = {
  start: number;
  end: number;
  peakTime: number;
  primaryState: ListeningLabel;
  scores: Partial<ListeningStateScores>;
};

export function emptyListeningLabels(): ListeningLabels {
  return {
    groove: 0,
    chill: 0,
    neutral: 0
  };
}

export function labelsToVector(labels: ListeningLabels): number[] {
  return LISTENING_LABELS.map((label) => labels[label]);
}

export function vectorToLabels(values: ArrayLike<number>, threshold = 0.5): ListeningLabels {
  const labels = emptyListeningLabels();
  LISTENING_LABELS.forEach((label, index) => {
    labels[label] = Number((values[index] ?? 0) >= threshold) as 0 | 1;
  });
  return labels;
}

export function vectorToScores(values: ArrayLike<number>): ListeningStateScores {
  return Object.fromEntries(
    LISTENING_LABELS.map((label, index) => [label, clampScore(values[index] ?? 0)])
  ) as ListeningStateScores;
}

export function topLabelsFromScores(
  scores: ListeningStateScores,
  threshold = 0.5,
  maxLabels = 2
): ListeningLabel[] {
  const ranked = [...LISTENING_LABELS].sort((a, b) => scores[b] - scores[a]);
  const aboveThreshold = ranked.filter((label) => scores[label] >= threshold);
  return (aboveThreshold.length > 0 ? aboveThreshold : ranked).slice(0, maxLabels);
}

export function assertFeatureVector(features: unknown): asserts features is number[] {
  if (!Array.isArray(features) || features.length !== FEATURE_KEYS.length) {
    throw new Error(`features must be an array of ${FEATURE_KEYS.length} numbers`);
  }

  features.forEach((value, index) => {
    if (typeof value !== "number" || !Number.isFinite(value)) {
      throw new Error(`features[${index}] must be a finite number`);
    }
  });
}

export function parseTrainingExample(line: string): TrainingExample {
  const parsed = JSON.parse(line) as TrainingExample;
  assertFeatureVector(parsed.features);

  for (const label of LISTENING_LABELS) {
    const value = parsed.labels?.[label];
    if (value !== 0 && value !== 1) {
      throw new Error(`labels.${label} must be 0 or 1`);
    }
  }

  return parsed;
}

function clampScore(value: number): number {
  if (!Number.isFinite(value)) {
    return 0;
  }
  return Math.max(0, Math.min(1, value));
}
