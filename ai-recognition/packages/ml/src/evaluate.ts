import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import * as tf from "@tensorflow/tfjs-node";
import { loadTrainingExamples } from "./train";
import { labelsToVector, LISTENING_LABELS } from "./schema";

const PACKAGE_DIR = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DEFAULT_DATA_PATH = path.join(PACKAGE_DIR, "data/examples.jsonl");
const DEFAULT_MODEL_DIR = path.join(PACKAGE_DIR, "models/motion-reaction-v1");

type LabelMetric = {
  label: string;
  precision: number;
  recall: number;
  f1: number;
  support: number;
};

async function main(): Promise<void> {
  const dataPath = path.resolve(getArg("--data", DEFAULT_DATA_PATH));
  const modelDir = path.resolve(getArg("--model", DEFAULT_MODEL_DIR));
  const examples = await loadTrainingExamples(dataPath);
  const model = await tf.loadLayersModel(
    pathToFileURL(path.join(modelDir, "model.json")).href
  );
  const threshold = Number(getArg("--threshold", "0.3"));
  const xs = tf.tensor2d(examples.map((example) => example.features));
  const predictionTensor = model.predict(xs) as tf.Tensor;
  const predictions = (await predictionTensor.array()) as number[][];
  const targets = examples.map((example) => labelsToVector(example.labels));
  const metrics = calculateMetrics(predictions, targets, threshold);

  console.log(JSON.stringify(metrics, null, 2));

  xs.dispose();
  predictionTensor.dispose();
  model.dispose();
}

export function calculateMetrics(predictions: number[][], targets: number[][], threshold = 0.3) {
  const labelMetrics: LabelMetric[] = LISTENING_LABELS.map((label, labelIndex) => {
    let tp = 0;
    let fp = 0;
    let fn = 0;
    let support = 0;

    predictions.forEach((prediction, index) => {
      const predicted = (prediction[labelIndex] ?? 0) >= threshold;
      const actual = (targets[index]?.[labelIndex] ?? 0) === 1;

      if (actual) {
        support += 1;
      }
      if (predicted && actual) {
        tp += 1;
      } else if (predicted && !actual) {
        fp += 1;
      } else if (!predicted && actual) {
        fn += 1;
      }
    });

    const precision = safeDivide(tp, tp + fp);
    const recall = safeDivide(tp, tp + fn);
    const f1 = safeDivide(2 * precision * recall, precision + recall);
    return { label, precision, recall, f1, support };
  });

  const macroF1 = safeDivide(
    labelMetrics.reduce((sum, metric) => sum + metric.f1, 0),
    labelMetrics.length
  );
  const top2Accuracy = safeDivide(
    predictions.filter((prediction, index) => {
      const top2 = prediction
        .map((score, labelIndex) => ({ score, labelIndex }))
        .sort((a, b) => b.score - a.score)
        .slice(0, 2)
        .map((item) => item.labelIndex);
      return top2.some((labelIndex) => (targets[index]?.[labelIndex] ?? 0) === 1);
    }).length,
    predictions.length
  );

  return { threshold, macroF1, top2Accuracy, labelMetrics };
}

function getArg(flag: string, fallback: string): string {
  const index = process.argv.indexOf(flag);
  return index >= 0 ? process.argv[index + 1] ?? fallback : fallback;
}

function safeDivide(numerator: number, denominator: number): number {
  return denominator === 0 ? 0 : numerator / denominator;
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? "").href) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
