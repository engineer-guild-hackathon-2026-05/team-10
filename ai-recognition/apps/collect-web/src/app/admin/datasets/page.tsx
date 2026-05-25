"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Music2, RefreshCcw } from "lucide-react";

type DatasetSummary = {
  sessions: Array<{
    id: string;
    songId: string;
    startedAt: string;
    sampleCount: number;
    labelCount: number;
    durationSec: number;
    listeningContext: {
      phonePosition: string;
      usualMovement: string;
    };
  }>;
  totals: {
    sessions: number;
    samples: number;
    labels: number;
    neutralRate: number;
  };
  labelCounts: Record<string, number>;
};

export default function DatasetsPage() {
  const [summary, setSummary] = useState<DatasetSummary | null>(null);

  async function loadSummary() {
    const response = await fetch("/api/admin/datasets");
    setSummary(await response.json());
  }

  useEffect(() => {
    void loadSummary();
  }, []);

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
        </nav>
      </header>

      <section className="screenHeader">
        <h1>Datasets</h1>
        <p>収集済みセッションの件数とラベル偏りを確認します。</p>
      </section>

      <section className="metricGrid">
        <Metric label="sessions" value={summary?.totals.sessions ?? 0} />
        <Metric label="samples" value={summary?.totals.samples ?? 0} />
        <Metric label="labels" value={summary?.totals.labels ?? 0} />
        <Metric label="neutral rate" value={`${Math.round((summary?.totals.neutralRate ?? 0) * 100)}%`} />
      </section>

      <section className="section">
        <div className="panel">
          <div className="panelHeader">
            <h2>操作</h2>
            <div className="statusRow">
              <button className="secondaryButton" onClick={loadSummary} type="button">
                <RefreshCcw size={18} />
                更新
              </button>
            </div>
          </div>
          <div className="panelBody">
            <div className="statusRow">
              {Object.entries(summary?.labelCounts ?? {}).map(([label, count]) => (
                <span className="statusPill" key={label}>
                  {label}: {count}
                </span>
              ))}
            </div>
          </div>
        </div>
      </section>

      <section className="section">
        <div className="panel">
          <div className="panelHeader">
            <h2>セッション一覧</h2>
            <span className="statusPill">{summary?.sessions.length ?? 0} rows</span>
          </div>
          <div className="panelBody tableWrap">
            <table>
              <thead>
                <tr>
                  <th>session</th>
                  <th>song</th>
                  <th>duration</th>
                  <th>samples</th>
                  <th>labels</th>
                  <th>position</th>
                  <th>started</th>
                </tr>
              </thead>
              <tbody>
                {(summary?.sessions ?? []).map((session) => (
                  <tr key={session.id}>
                    <td>
                      <Link href={`/collect/review/${session.id}`}>{session.id}</Link>
                    </td>
                    <td>{session.songId}</td>
                    <td>{session.durationSec.toFixed(1)}s</td>
                    <td>{session.sampleCount}</td>
                    <td>{session.labelCount}</td>
                    <td>{session.listeningContext.phonePosition}</td>
                    <td>{new Date(session.startedAt).toLocaleString("ja-JP")}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>
    </main>
  );
}

function Metric({ label, value }: { label: string; value: number | string }) {
  return (
    <div className="metric">
      <span className="metricValue">{value}</span>
      <span className="metricLabel">{label}</span>
    </div>
  );
}
