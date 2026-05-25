"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { Activity, ArrowRight, CheckCircle2, Music2, ShieldCheck } from "lucide-react";
import { DEMO_SONGS } from "@/lib/songs";

type PermissionState = "idle" | "granted" | "denied" | "tap_only";

type DeviceMotionEventWithPermission = typeof DeviceMotionEvent & {
  requestPermission?: () => Promise<"granted" | "denied">;
};

export default function StartPage() {
  const router = useRouter();
  const [songId, setSongId] = useState(DEMO_SONGS[0]?.id ?? "groove-demo");
  const [phonePosition, setPhonePosition] = useState<"hand" | "table" | "pocket">("hand");
  const [dominantHand, setDominantHand] = useState<"right" | "left" | "unknown">("right");
  const [usualMovement, setUsualMovement] = useState<"active" | "still" | "depends">("depends");
  const [permission, setPermission] = useState<PermissionState>("idle");
  const [saving, setSaving] = useState(false);

  async function requestSensorPermission() {
    if (typeof window === "undefined" || !("DeviceMotionEvent" in window)) {
      setPermission("tap_only");
      return;
    }

    const MotionEvent = DeviceMotionEvent as DeviceMotionEventWithPermission;
    if (typeof MotionEvent.requestPermission === "function") {
      const result = await MotionEvent.requestPermission();
      setPermission(result === "granted" ? "granted" : "denied");
      return;
    }

    setPermission("granted");
  }

  async function startSession() {
    setSaving(true);
    const response = await fetch("/api/collect/session", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        songId,
        phonePosition,
        dominantHand,
        usualMovement,
        screenWidth: window.screen.width,
        screenHeight: window.screen.height
      })
    });
    const data = await response.json();
    router.push(`/collect/session/${data.sessionId}`);
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
          <Link href="/admin/datasets">Datasets</Link>
        </nav>
      </header>

      <section className="screenHeader">
        <h1>学習データ収集セッション</h1>
        <p>
          音楽を聴きながら近い反応ラベルを押すと、スマホの動きと曲中タイムスタンプを結びつけて保存します。
        </p>
      </section>

      <div className="gridTwo">
        <section className="panel">
          <div className="panelHeader">
            <h2>曲</h2>
            <span className="statusPill">
              <Music2 size={15} /> Web Audio
            </span>
          </div>
          <div className="panelBody songList">
            {DEMO_SONGS.map((song) => (
              <button
                className={`songOption ${songId === song.id ? "songOptionActive" : ""}`}
                key={song.id}
                onClick={() => setSongId(song.id)}
                type="button"
              >
                <span className="songTitle">{song.title}</span>
                <span className="songDescription">{song.description}</span>
              </button>
            ))}
          </div>
        </section>

        <section className="panel">
          <div className="panelHeader">
            <h2>収集条件</h2>
            <span className="statusPill">
              <ShieldCheck size={15} /> 音声・位置情報なし
            </span>
          </div>
          <div className="panelBody formGrid">
            <label className="field">
              <span>スマホの持ち方</span>
              <div className="segmented">
                {[
                  ["hand", "手に持つ"],
                  ["table", "机に置く"],
                  ["pocket", "ポケット"]
                ].map(([value, label]) => (
                  <button
                    className={`segment ${phonePosition === value ? "segmentActive" : ""}`}
                    key={value}
                    onClick={() => setPhonePosition(value as typeof phonePosition)}
                    type="button"
                  >
                    {label}
                  </button>
                ))}
              </div>
            </label>

            <label className="field">
              <span>利き手</span>
              <select
                className="select"
                value={dominantHand}
                onChange={(event) => setDominantHand(event.target.value as typeof dominantHand)}
              >
                <option value="right">右</option>
                <option value="left">左</option>
                <option value="unknown">わからない</option>
              </select>
            </label>

            <label className="field">
              <span>普段の聴き方</span>
              <select
                className="select"
                value={usualMovement}
                onChange={(event) => setUsualMovement(event.target.value as typeof usualMovement)}
              >
                <option value="active">普段から身体を動かす</option>
                <option value="still">あまり動かない</option>
                <option value="depends">曲による</option>
              </select>
            </label>

            <div className="statusRow">
              <button className="secondaryButton" onClick={requestSensorPermission} type="button">
                <Activity size={18} />
                センサー許可
              </button>
              <span className="statusPill">
                <CheckCircle2 size={15} />
                {permission === "granted"
                  ? "取得できます"
                  : permission === "denied"
                    ? "タップのみ"
                    : permission === "tap_only"
                      ? "タップのみ"
                      : "未確認"}
              </span>
            </div>

            <button className="primaryButton" disabled={saving} onClick={startSession} type="button">
              <ArrowRight size={18} />
              セッション開始
            </button>
          </div>
        </section>
      </div>
    </main>
  );
}

