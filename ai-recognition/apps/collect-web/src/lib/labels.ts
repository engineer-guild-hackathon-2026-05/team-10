import type { CollectionLabel, ListeningLabel } from "@howtune/ml/schema";
import {
  Circle,
  Moon,
  Waves
} from "lucide-react";
import type { ComponentType } from "react";

export type LabelConfig = {
  label: ListeningLabel;
  name: string;
  shortHint: string;
  className: string;
  Icon: ComponentType<{ size?: number; strokeWidth?: number }>;
  beforeSec: number;
  afterSec: number;
};

export const LABEL_CONFIGS: LabelConfig[] = [
  {
    label: "groove",
    name: "ノってる",
    shortHint: "リズムに合った揺れ",
    className: "labelGroove",
    Icon: Waves,
    beforeSec: 5,
    afterSec: 5
  },
  {
    label: "chill",
    name: "チルい",
    shortHint: "小さく心地よい揺れ",
    className: "labelChill",
    Icon: Moon,
    beforeSec: 5,
    afterSec: 5
  },
  {
    label: "neutral",
    name: "neutral",
    shortHint: "特に反応なし",
    className: "labelNeutral",
    Icon: Circle,
    beforeSec: 5,
    afterSec: 5
  }
];

export function getLabelConfig(label: CollectionLabel): LabelConfig | undefined {
  return LABEL_CONFIGS.find((config) => config.label === label);
}
