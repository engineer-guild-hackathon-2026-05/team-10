import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import * as tf from "@tensorflow/tfjs-node";
import { extractFeatureWindows, type FeatureWindow } from "./features";
import {
  LISTENING_LABELS,
  topLabelsFromScores,
  type ListeningLabel,
  type ListeningStateScores,
  type MotionSample,
  type PredictionWindow,
  type ReactionCandidate,
  vectorToScores
} from "./schema";

export type PredictMotionRequest = {
  sessionId: string;
  songId: string;
  samples: MotionSample[];
};

export type PredictMotionResponse = {
  sessionId: string;
  songId: string;
  modelVersion: string;
  windows: PredictionWindow[];
  reactionCandidates: ReactionCandidate[];
};

export type PredictOptions = {
  modelDir?: string;
  threshold?: number;
  maxCandidates?: number;
  allowHeuristicFallback?: boolean;
};

const PACKAGE_DIR = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DEFAULT_MODEL_DIR = path.join(PACKAGE_DIR, "models/motion-reaction-v1");

export async function predictMotionReaction(
  request: PredictMotionRequest,
  options: PredictOptions = {}
): Promise<PredictMotionResponse> {
  const threshold = options.threshold ?? 0.3;
  const featureWindows = extractFeatureWindows(request.samples);
  const scores = await predictScores(featureWindows, options);
  const windows = featureWindows.map((window, index) => {
    const windowScores = scores[index] ?? heuristicScoresFromFeatures(window);
    return {
      start: window.start,
      end: window.end,
      scores: windowScores,
      topLabels: topLabelsFromScores(windowScores, threshold, 2)
    };
  });

  return {
    sessionId: request.sessionId,
    songId: request.songId,
    modelVersion: scores.modelVersion ?? "motion-reaction-v1",
    windows,
    reactionCandidates: buildReactionCandidates(
      windows,
      threshold,
      options.maxCandidates ?? 5
    )
  };
}

async function predictScores(
  featureWindows: FeatureWindow[],
  options: PredictOptions
): Promise<ListeningStateScores[] & { modelVersion?: string }> {
  if (featureWindows.length === 0) {
    return [] as ListeningStateScores[] & { modelVersion?: string };
  }

  try {
    const modelDir = options.modelDir ?? DEFAULT_MODEL_DIR;
    const model = await tf.loadLayersModel(
      pathToFileURL(path.join(modelDir, "model.json")).href
    );
    const xs = tf.tensor2d(featureWindows.map((window) => window.features));
    const predictionTensor = model.predict(xs) as tf.Tensor;
    const predictionRows = (await predictionTensor.array()) as number[][];
    const result = predictionRows.map((row) => vectorToScores(row)) as ListeningStateScores[] & {
      modelVersion?: string;
    };
    result.modelVersion = path.basename(modelDir);

    xs.dispose();
    predictionTensor.dispose();
    model.dispose();
    return result;
  } catch (error) {
    if (!options.allowHeuristicFallback) {
      throw error;
    }

    const result = featureWindows.map((window) =>
      heuristicScoresFromFeatures(window)
    ) as ListeningStateScores[] & { modelVersion?: string };
    result.modelVersion = "heuristic-bootstrap";
    return result;
  }
}

export function buildReactionCandidates(
  windows: PredictionWindow[],
  threshold = 0.5,
  maxCandidates = 5
): ReactionCandidate[] {
  const activeWindows = windows
    .map((window) => {
      const primaryState = window.topLabels[0];
      const score = primaryState ? window.scores[primaryState] : 0;
      return primaryState && score >= threshold ? { ...window, primaryState, score } : null;
    })
    .filter(Boolean) as Array<PredictionWindow & { primaryState: ListeningLabel; score: number }>;

  const groups: Array<Array<PredictionWindow & { primaryState: ListeningLabel; score: number }>> =
    [];

  for (const window of activeWindows) {
    const lastGroup = groups.at(-1);
    const lastWindow = lastGroup?.at(-1);

    if (
      lastGroup &&
      lastWindow &&
      lastWindow.primaryState === window.primaryState &&
      window.start - lastWindow.end <= 1.1
    ) {
      lastGroup.push(window);
    } else {
      groups.push([window]);
    }
  }

  return groups
    .map((group) => {
      const strongest = group.toSorted((a, b) => b.score - a.score)[0]!;
      const scoreSummary = Object.fromEntries(
        strongest.topLabels.map((label) => [label, strongest.scores[label]])
      ) as Partial<ListeningStateScores>;

      return {
        start: group[0]?.start ?? 0,
        end: group.at(-1)?.end ?? 0,
        peakTime: ((strongest.start + strongest.end) / 2),
        primaryState: strongest.primaryState,
        scores: scoreSummary
      };
    })
    .toSorted((a, b) => {
      const bScore = b.scores[b.primaryState] ?? 0;
      const aScore = a.scores[a.primaryState] ?? 0;
      return bScore - aScore;
    })
    .slice(0, maxCandidates)
    .toSorted((a, b) => a.start - b.start);
}

function heuristicScoresFromFeatures(window: FeatureWindow): ListeningStateScores {
  const stdMagnitude = window.features[1] ?? 0;
  const meanDelta = window.features[2] ?? 0;
  const maxDelta = window.features[3] ?? 0;
  const energy = window.features[4] ?? 0;
  const peakCount = window.features[5] ?? 0;
  const rhythmRegularity = window.features[6] ?? 0;
  const stillness = window.features[7] ?? 0;
  const previousEnergyDiff = window.features[8] ?? 0;

  return {
    groove: sigmoid(0.8 * rhythmRegularity + 0.35 * peakCount + 0.25 * energy - 0.2 * maxDelta),
    hype: sigmoid(0.75 * energy + 0.7 * maxDelta + 0.4 * stdMagnitude + 0.55 * previousEnergyDiff),
    chill: sigmoid(0.7 * rhythmRegularity + 0.3 * stillness - 0.45 * maxDelta - 0.25 * energy),
    immersion: sigmoid(1.1 * stillness - 0.5 * meanDelta - 0.45 * peakCount),
    hit: sigmoid(1.0 * maxDelta + 0.75 * previousEnergyDiff - 0.35 * peakCount),
    afterglow: sigmoid(1.0 * stillness - 0.85 * energy - 0.8 * previousEnergyDiff)
  };
}

function sigmoid(value = 0): number {
  return 1 / (1 + Math.exp(-value));
}

async function main(): Promise<void> {
  const inputPath = process.argv[2];
  if (!inputPath) {
    throw new Error("Usage: npm run ml:predict -- <request.json>");
  }

  const fs = await import("node:fs/promises");
  const request = JSON.parse(await fs.readFile(inputPath, "utf8")) as PredictMotionRequest;
  const response = await predictMotionReaction(request, { allowHeuristicFallback: true });
  console.log(JSON.stringify(response, null, 2));
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? "").href) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
