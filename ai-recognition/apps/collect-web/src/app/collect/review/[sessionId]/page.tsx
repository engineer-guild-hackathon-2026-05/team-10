"use client";

import { useEffect, useMemo, useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { Music2, Save, Trash2 } from "lucide-react";
import type { LabelEvent, MotionSample } from "@howtune/ml/schema";
import { getLabelConfig, LABEL_CONFIGS } from "@/lib/labels";
import { getDemoSong } from "@/lib/songs";

type Bundle = {
  session: {
    id: string;
    songId: string;
  };
  samples: MotionSample[];
  labels: LabelEvent[];
};

export default function ReviewPage() {
  const params = useParams<{ sessionId: string }>();
  const sessionId = params.sessionId;
  const [bundle, setBundle] = useState<Bundle | null>(null);
  const [labels, setLabels] = useState<LabelEvent[]>([]);
  const song = useMemo(() => getDemoSong(bundle?.session.songId ?? "groove-demo"), [bundle]);
  const duration = Math.max(song.durationSec, bundle?.samples.at(-1)?.t ?? song.durationSec);

  useEffect(() => {
    fetch(`/api/collect/session/${sessionId}`)
      .then((response) => response.json())
      .then((data) => {
        setBundle(data);
        setLabels(data.labels ?? []);
      });
  }, [sessionId]);

  async function saveLabels() {
    await fetch("/api/collect/review", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ sessionId, labels })
    });
    const response = await fetch(`/api/collect/session/${sessionId}`);
    const data = await response.json();
    setBundle(data);
    setLabels(data.labels ?? []);
  }

  function updateLabel(id: string, patch: Partial<LabelEvent>) {
    setLabels((items) => items.map((item) => (item.id === id ? { ...item, ...patch } : item)));
  }

  function removeLabel(id: string) {
    setLabels((items) => items.filter((item) => item.id !== id));
  }

  return (
    <main className="appShell">
      <header className="topBar">
        <div className="brand">
          <span className="brandMark">
            <Music2 size={18} />
          </span>
          HowTune Collector
        </div>
        <nav className="navLinks">
          <Link href="/collect/start">Start</Link>
          <Link href="/admin/datasets">Datasets</Link>
        </nav>
      </header>

      <section className="screenHeader">
        <h1>レビュー</h1>
        <p>ラベル区間を確認して、必要なら3状態の範囲を直せます。</p>
      </section>

      <section className="panel">
        <div className="panelHeader">
          <h2>{song.title}</h2>
          <div className="statusRow">
            <button className="primaryButton" onClick={saveLabels} type="button">
              <Save size={18} />
              保存
            </button>
          </div>
        </div>
        <div className="panelBody formGrid">
          <div className="timeline">
            {labels.map((label) => {
              const config = getLabelConfig(label.label);
              const left = (label.startedAtSec / duration) * 100;
              const width = Math.max(2, ((label.endedAtSec - label.startedAtSec) / duration) * 100);
              return (
                <div
                  className={`timelineBar ${config?.className ?? "labelNeutral"}`}
                  key={label.id}
                  style={{ left: `${left}%`, width: `${width}%` }}
                >
                  {config?.name ?? label.label}
                </div>
              );
            })}
          </div>
          <SensorGraph samples={bundle?.samples ?? []} />
        </div>
      </section>

      <section className="section">
        <div className="panel">
          <div className="panelHeader">
            <h2>ラベル編集</h2>
            <span className="statusPill">{labels.length} events</span>
          </div>
          <div className="panelBody labelEditor">
            {labels.map((label) => (
              <div className="labelRow" key={label.id}>
                <select
                  className="select"
                  value={label.label}
                  onChange={(event) => updateLabel(label.id, { label: event.target.value as LabelEvent["label"] })}
                >
                  {LABEL_CONFIGS.map((config) => (
                    <option key={config.label} value={config.label}>
                      {config.name}
                    </option>
                  ))}
                </select>
                <input
                  className="input"
                  min={0}
                  step={0.1}
                  type="number"
                  value={label.startedAtSec}
                  onChange={(event) =>
                    updateLabel(label.id, { startedAtSec: Number(event.target.value) })
                  }
                />
                <input
                  className="input"
                  min={0}
                  step={0.1}
                  type="number"
                  value={label.endedAtSec}
                  onChange={(event) =>
                    updateLabel(label.id, { endedAtSec: Number(event.target.value) })
                  }
                />
                <button className="iconButton" onClick={() => removeLabel(label.id)} type="button" aria-label="削除">
                  <Trash2 size={18} />
                </button>
              </div>
            ))}
          </div>
        </div>
      </section>
    </main>
  );
}

function SensorGraph({ samples }: { samples: MotionSample[] }) {
  const points = useMemo(() => {
    if (samples.length === 0) {
      return "";
    }

    const maxT = samples.at(-1)?.t ?? 1;
    const magnitudes = samples.map((sample) => ({
      t: sample.t,
      value: Math.sqrt(sample.ax ** 2 + sample.ay ** 2 + sample.az ** 2)
    }));
    const min = Math.min(...magnitudes.map((item) => item.value));
    const max = Math.max(...magnitudes.map((item) => item.value));
    return magnitudes
      .filter((_, index) => index % Math.max(1, Math.floor(magnitudes.length / 240)) === 0)
      .map((item) => {
        const x = (item.t / maxT) * 1000;
        const y = 120 - ((item.value - min) / Math.max(0.001, max - min)) * 100;
        return `${x.toFixed(1)},${y.toFixed(1)}`;
      })
      .join(" ");
  }, [samples]);

  return (
    <svg className="graph" viewBox="0 0 1000 140" role="img" aria-label="センサー強度グラフ">
      <polyline fill="none" points={points} stroke="#0f8b8d" strokeWidth="4" />
    </svg>
  );
}
