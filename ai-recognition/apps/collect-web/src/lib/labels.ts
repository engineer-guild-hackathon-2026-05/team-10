import type { CollectionLabel, ListeningLabel } from "@howtune/ml/schema";
import {
  Activity,
  Flame,
  Focus,
  HandMetal,
  Moon,
  Sparkles,
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
    label: "hype",
    name: "上がった",
    shortHint: "展開やサビで反応",
    className: "labelHype",
    Icon: Flame,
    beforeSec: 2,
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
    label: "immersion",
    name: "聴き入ってる",
    shortHint: "静かに集中",
    className: "labelImmersion",
    Icon: Focus,
    beforeSec: 1,
    afterSec: 4
  },
  {
    label: "hit",
    name: "刺さった",
    shortHint: "一瞬の音や歌詞",
    className: "labelHit",
    Icon: Sparkles,
    beforeSec: 1.5,
    afterSec: 1.5
  },
  {
    label: "afterglow",
    name: "余韻",
    shortHint: "反応後に味わう",
    className: "labelAfterglow",
    Icon: HandMetal,
    beforeSec: 2,
    afterSec: 6
  }
];

export const AUX_LABELS: Array<{ label: CollectionLabel; name: string; Icon: typeof Activity }> = [
  { label: "noise", name: "ノイズ", Icon: Activity },
  { label: "unknown", name: "わからない", Icon: Activity },
  { label: "phone_on_table", name: "置いていた", Icon: Activity }
];

export function getLabelConfig(label: CollectionLabel): LabelConfig | undefined {
  return LABEL_CONFIGS.find((config) => config.label === label);
}

