import {
  emptyListeningLabels,
  FEATURE_KEYS,
  type FeatureKey,
  type LabelEvent,
  LISTENING_LABELS,
  type MotionFeatures,
  type MotionSample,
  type TrainingExample
} from "./schema";

export type FeatureExtractionOptions = {
  windowDurationSec?: number;
  strideSec?: number;
  normalize?: boolean;
  peakThresholdStd?: number;
};

export type FeatureWindow = {
  start: number;
  end: number;
  rawFeatures: MotionFeatures;
  features: number[];
};

const EPSILON = 1e-9;
const DEFAULT_WINDOW_DURATION_SEC = 3;
const DEFAULT_STRIDE_SEC = 1;

export function extractFeatureWindows(
  samples: MotionSample[],
  options: FeatureExtractionOptions = {}
): FeatureWindow[] {
  const windowDurationSec = options.windowDurationSec ?? DEFAULT_WINDOW_DURATION_SEC;
  const strideSec = options.strideSec ?? DEFAULT_STRIDE_SEC;
  const normalize = options.normalize ?? true;
  const sortedSamples = samples
    .filter(isValidMotionSample)
    .toSorted((a, b) => a.t - b.t);

  if (sortedSamples.length < 2) {
    return [];
  }

  const firstT = sortedSamples[0]?.t ?? 0;
  const lastT = sortedSamples.at(-1)?.t ?? firstT;
  const windows: Array<Omit<FeatureWindow, "features">> = [];
  let previousEnergy = 0;

  for (
    let start = firstT;
    start + windowDurationSec <= lastT + EPSILON;
    start += strideSec
  ) {
    const end = start + windowDurationSec;
    const windowSamples = sortedSamples.filter((sample) => sample.t >= start && sample.t < end);

    if (windowSamples.length < 2) {
      continue;
    }

    const rawFeatures = calculateWindowFeatures(
      windowSamples,
      previousEnergy,
      windowDurationSec,
      options.peakThresholdStd ?? 0.5
    );

    previousEnergy = rawFeatures.energy;
    windows.push({ start: roundSec(start), end: roundSec(end), rawFeatures });
  }

  if (!normalize) {
    return windows.map((window) => ({
      ...window,
      features: featureObjectToVector(window.rawFeatures)
    }));
  }

  return normalizeFeatureWindows(windows, windowDurationSec);
}

export function calculateWindowFeatures(
  samples: MotionSample[],
  previousEnergy: number,
  windowDurationSec: number,
  peakThresholdStd = 0.5
): MotionFeatures {
  const magnitudes = samples.map((sample) => magnitude(sample));
  const deltas = magnitudes.map((value, index) =>
    index === 0 ? 0 : Math.abs(value - (magnitudes[index - 1] ?? value))
  );
  const peakIndexes = findPeakIndexes(deltas, peakThresholdStd);
  const peakIntervals = peakIndexes
    .slice(1)
    .map((peakIndex, index) => (samples[peakIndex]?.t ?? 0) - (samples[peakIndexes[index] ?? 0]?.t ?? 0))
    .filter((interval) => interval > 0);

  const meanMagnitude = mean(magnitudes);
  const stdMagnitude = stddev(magnitudes, meanMagnitude);
  const meanDelta = mean(deltas);
  const maxDelta = Math.max(...deltas);
  const energy = deltas.reduce((sum, delta) => sum + delta * delta, 0);
  const rhythmRegularity = calculateRhythmRegularity(peakIntervals);
  const energyPerSec = energy / Math.max(windowDurationSec, EPSILON);
  const stillness = clamp01((1 - meanDelta / 0.35) * (1 - energyPerSec / 2.5));

  return {
    meanMagnitude,
    stdMagnitude,
    meanDelta,
    maxDelta,
    energy,
    peakCount: peakIndexes.length,
    rhythmRegularity,
    stillness,
    previousEnergyDiff: energy - previousEnergy,
    windowDurationSec
  };
}

export function createTrainingExamplesFromSession(input: {
  sessionId: string;
  songId: string;
  samples: MotionSample[];
  labels: LabelEvent[];
  meta?: TrainingExample["meta"];
  windowDurationSec?: number;
  strideSec?: number;
}): TrainingExample[] {
  const windowDurationSec = input.windowDurationSec ?? DEFAULT_WINDOW_DURATION_SEC;
  const windows = extractFeatureWindows(input.samples, {
    windowDurationSec,
    strideSec: input.strideSec ?? DEFAULT_STRIDE_SEC,
    normalize: true
  });

  return windows
    .map((window) => {
      const labels = emptyListeningLabels();

      for (const event of input.labels) {
        if (!LISTENING_LABELS.includes(event.label as (typeof LISTENING_LABELS)[number])) {
          continue;
        }

        const overlapRatio =
          overlapDuration(window.start, window.end, event.startedAtSec, event.endedAtSec) /
          (window.end - window.start);

        if (overlapRatio >= 0.5) {
          labels[event.label as keyof typeof labels] = 1;
        }
      }

      return {
        id: `${input.sessionId}_${window.start.toFixed(2)}_${window.end.toFixed(2)}`,
        sessionId: input.sessionId,
        songId: input.songId,
        windowStart: window.start,
        windowEnd: window.end,
        features: window.features,
        labels,
        meta: input.meta ?? {}
      };
    });
}

export function featureObjectToVector(features: MotionFeatures): number[] {
  return FEATURE_KEYS.map((key) => features[key]);
}

function normalizeFeatureWindows(
  windows: Array<Omit<FeatureWindow, "features">>,
  nominalWindowDurationSec: number
): FeatureWindow[] {
  const normalizableKeys = FEATURE_KEYS.filter((key) => key !== "windowDurationSec");
  const stats = new Map<FeatureKey, { mean: number; std: number }>();

  for (const key of normalizableKeys) {
    const values = windows.map((window) => window.rawFeatures[key]);
    const valueMean = mean(values);
    stats.set(key, { mean: valueMean, std: stddev(values, valueMean) || 1 });
  }

  return windows.map((window) => {
    const features = FEATURE_KEYS.map((key) => {
      if (key === "windowDurationSec") {
        return window.rawFeatures.windowDurationSec / nominalWindowDurationSec;
      }

      const stat = stats.get(key);
      return stat ? (window.rawFeatures[key] - stat.mean) / stat.std : window.rawFeatures[key];
    });

    return { ...window, features };
  });
}

function findPeakIndexes(values: number[], thresholdStd: number): number[] {
  if (values.length < 3) {
    return [];
  }

  const valueMean = mean(values);
  const threshold = valueMean + stddev(values, valueMean) * thresholdStd;
  const peakIndexes: number[] = [];

  for (let index = 1; index < values.length - 1; index += 1) {
    const value = values[index] ?? 0;
    if (value >= threshold && value >= (values[index - 1] ?? 0) && value > (values[index + 1] ?? 0)) {
      peakIndexes.push(index);
    }
  }

  return peakIndexes;
}

function calculateRhythmRegularity(peakIntervals: number[]): number {
  if (peakIntervals.length < 2) {
    return 0;
  }

  const intervalMean = mean(peakIntervals);
  const intervalVariance = variance(peakIntervals, intervalMean);
  return clamp01(1 - intervalVariance / (intervalMean * intervalMean + EPSILON));
}

function overlapDuration(aStart: number, aEnd: number, bStart: number, bEnd: number): number {
  return Math.max(0, Math.min(aEnd, bEnd) - Math.max(aStart, bStart));
}

function magnitude(sample: MotionSample): number {
  return Math.sqrt(sample.ax * sample.ax + sample.ay * sample.ay + sample.az * sample.az);
}

function mean(values: number[]): number {
  return values.length === 0 ? 0 : values.reduce((sum, value) => sum + value, 0) / values.length;
}

function variance(values: number[], valueMean = mean(values)): number {
  return values.length === 0
    ? 0
    : values.reduce((sum, value) => sum + (value - valueMean) ** 2, 0) / values.length;
}

function stddev(values: number[], valueMean = mean(values)): number {
  return Math.sqrt(variance(values, valueMean));
}

function clamp01(value: number): number {
  return Math.max(0, Math.min(1, Number.isFinite(value) ? value : 0));
}

function roundSec(value: number): number {
  return Math.round(value * 1000) / 1000;
}

function isValidMotionSample(sample: MotionSample): boolean {
  return [sample.t, sample.ax, sample.ay, sample.az].every(
    (value) => typeof value === "number" && Number.isFinite(value)
  );
}
