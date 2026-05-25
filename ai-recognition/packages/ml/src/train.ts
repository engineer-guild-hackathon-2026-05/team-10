import * as fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import * as tf from "@tensorflow/tfjs-node";
import { compileMotionReactionModel } from "./model";
import { labelsToVector, parseTrainingExample, type TrainingExample } from "./schema";

type TrainArgs = {
  dataPath: string;
  outDir: string;
  epochs: number;
  batchSize: number;
  validationSplit: number;
};

const PACKAGE_DIR = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DEFAULT_DATA_PATH = path.join(PACKAGE_DIR, "data/examples.jsonl");
const DEFAULT_OUT_DIR = path.join(PACKAGE_DIR, "models/motion-reaction-v1");

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));
  const examples = await loadTrainingExamples(args.dataPath);

  if (examples.length < 6) {
    throw new Error("At least 6 training examples are required for a useful MVP split.");
  }

  const shuffled = deterministicShuffle(examples, 42);
  const xs = tf.tensor2d(shuffled.map((example) => example.features));
  const ys = tf.tensor2d(shuffled.map((example) => labelsToVector(example.labels)));
  const model = compileMotionReactionModel();

  const history = await model.fit(xs, ys, {
    epochs: args.epochs,
    batchSize: args.batchSize,
    validationSplit: args.validationSplit,
    shuffle: true,
    callbacks: {
      onEpochEnd: (epoch, logs) => {
        const loss = logs?.loss?.toFixed(4) ?? "n/a";
        const valLoss = logs?.val_loss?.toFixed(4) ?? "n/a";
        console.log(`epoch=${epoch + 1} loss=${loss} val_loss=${valLoss}`);
      }
    }
  });

  await fs.mkdir(args.outDir, { recursive: true });
  await model.save(pathToFileURL(args.outDir).href);
  await renameSingleWeightShard(args.outDir);
  await writeMetadata(args.outDir, args, shuffled, history.history);

  xs.dispose();
  ys.dispose();
  model.dispose();
  console.log(`Saved MotionReactionClassifier to ${args.outDir}`);
}

export async function loadTrainingExamples(dataPath: string): Promise<TrainingExample[]> {
  const raw = await fs.readFile(dataPath, "utf8");
  return raw
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line, index) => {
      try {
        return parseTrainingExample(line);
      } catch (error) {
        throw new Error(`Invalid JSONL at line ${index + 1}: ${(error as Error).message}`);
      }
    });
}

async function renameSingleWeightShard(outDir: string): Promise<void> {
  const modelJsonPath = path.join(outDir, "model.json");
  const modelJson = JSON.parse(await fs.readFile(modelJsonPath, "utf8")) as {
    weightsManifest?: Array<{ paths: string[] }>;
  };
  const files = await fs.readdir(outDir);
  const shard = files.find((file) => /^group\d+-shard\d+of\d+\.bin$/.test(file));

  if (!shard || shard === "weights.bin") {
    return;
  }

  await fs.rename(path.join(outDir, shard), path.join(outDir, "weights.bin"));

  if (modelJson.weightsManifest?.length === 1) {
    modelJson.weightsManifest[0]!.paths = ["weights.bin"];
    await fs.writeFile(modelJsonPath, `${JSON.stringify(modelJson, null, 2)}\n`);
  }
}

async function writeMetadata(
  outDir: string,
  args: TrainArgs,
  examples: TrainingExample[],
  history: tf.History["history"]
): Promise<void> {
  const labelCounts = examples.reduce<Record<string, number>>((counts, example) => {
    for (const [label, value] of Object.entries(example.labels)) {
      counts[label] = (counts[label] ?? 0) + value;
    }
    return counts;
  }, {});

  await fs.writeFile(
    path.join(outDir, "metadata.json"),
    `${JSON.stringify(
      {
        modelName: "MotionReactionClassifier",
        trainedAt: new Date().toISOString(),
        examples: examples.length,
        labelCounts,
        training: {
          epochs: args.epochs,
          batchSize: args.batchSize,
          validationSplit: args.validationSplit
        },
        history
      },
      null,
      2
    )}\n`
  );
}

function parseArgs(argv: string[]): TrainArgs {
  const getValue = (flag: string, fallback: string): string => {
    const index = argv.indexOf(flag);
    return index >= 0 ? argv[index + 1] ?? fallback : fallback;
  };

  return {
    dataPath: path.resolve(getValue("--data", DEFAULT_DATA_PATH)),
    outDir: path.resolve(getValue("--out", DEFAULT_OUT_DIR)),
    epochs: Number(getValue("--epochs", "120")),
    batchSize: Number(getValue("--batch", "16")),
    validationSplit: Number(getValue("--validationSplit", "0.2"))
  };
}

function deterministicShuffle<T>(items: T[], seed: number): T[] {
  const output = [...items];
  let state = seed;

  for (let index = output.length - 1; index > 0; index -= 1) {
    state = (state * 1664525 + 1013904223) % 2 ** 32;
    const swapIndex = state % (index + 1);
    [output[index], output[swapIndex]] = [output[swapIndex] as T, output[index] as T];
  }

  return output;
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? "").href) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
