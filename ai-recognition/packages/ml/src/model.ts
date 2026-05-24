import * as tf from "@tensorflow/tfjs-node";
import { FEATURE_KEYS, LISTENING_LABELS } from "./schema";

export function createMotionReactionClassifier(): tf.Sequential {
  const model = tf.sequential({ name: "MotionReactionClassifier" });

  model.add(
    tf.layers.dense({
      inputShape: [FEATURE_KEYS.length],
      units: 32,
      activation: "relu",
      name: "feature_projection"
    })
  );
  model.add(tf.layers.dropout({ rate: 0.2, name: "regularization" }));
  model.add(tf.layers.dense({ units: 16, activation: "relu", name: "state_embedding" }));
  model.add(
    tf.layers.dense({
      units: LISTENING_LABELS.length,
      activation: "sigmoid",
      name: "listening_state_scores"
    })
  );

  return model;
}

export function compileMotionReactionModel(
  model = createMotionReactionClassifier(),
  learningRate = 0.001
): tf.Sequential {
  model.compile({
    optimizer: tf.train.adam(learningRate),
    loss: "binaryCrossentropy",
    metrics: ["binaryAccuracy"]
  });

  return model;
}

