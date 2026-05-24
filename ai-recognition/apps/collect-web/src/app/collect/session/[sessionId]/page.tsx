"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import {
  Activity,
  CircleStop,
  Gauge,
  Music2,
  Pause,
  Play,
  RotateCcw,
  Save
} from "lucide-react";
import type { LabelEvent, MotionSample } from "@howtune/ml/schema";
import { LABEL_CONFIGS } from "@/lib/labels";
import { getDemoSong, type DemoSong } from "@/lib/songs";

type SessionBundle = {
  session: {
    id: string;
    songId: string;
  };
  samples: MotionSample[];
  labels: LabelEvent[];
};

type AudioContextCtor = typeof AudioContext;

export default function SessionPage() {
  const params = useParams<{ sessionId: string }>();
  const router = useRouter();
  const sessionId = params.sessionId;
  const [bundle, setBundle] = useState<SessionBundle | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [sensorEnabled, setSensorEnabled] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [currentMagnitude, setCurrentMagnitude] = useState(0);
  const [savedLabels, setSavedLabels] = useState<LabelEvent[]>([]);
  const [chunkIndex, setChunkIndex] = useState(0);
  const [lastLabelName, setLastLabelName] = useState("まだなし");
  const currentTimeRef = useRef(0);
  const pendingSamplesRef = useRef<MotionSample[]>([]);
  const audioContextRef = useRef<AudioContext | null>(null);
  const timerRef = useRef<number | null>(null);

  const song = useMemo(() => getDemoSong(bundle?.session.songId ?? "groove-demo"), [bundle]);
  const progress = Math.min(100, (currentTime / song.durationSec) * 100);

  useEffect(() => {
    fetch(`/api/collect/session/${sessionId}`)
      .then((response) => response.json())
      .then((data) => {
        setBundle(data);
        setSavedLabels(data.labels ?? []);
      });
  }, [sessionId]);

  const flushMotion = useCallback(async () => {
    const samples = pendingSamplesRef.current.splice(0);
    if (samples.length === 0) {
      return;
    }

    const nextChunkIndex = chunkIndex;
    setChunkIndex((value) => value + 1);
    await fetch("/api/collect/motion", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ sessionId, chunkIndex: nextChunkIndex, samples })
    });
  }, [chunkIndex, sessionId]);

  useEffect(() => {
    if (!sensorEnabled) {
      return;
    }

    const handleMotion = (event: DeviceMotionEvent) => {
      if (!isPlaying) {
        return;
      }

      const acceleration = event.accelerationIncludingGravity ?? event.acceleration;
      const sample = {
        t: roundTime(currentTimeRef.current),
        ax: acceleration?.x ?? 0,
        ay: acceleration?.y ?? 0,
        az: acceleration?.z ?? 0,
        gx: event.rotationRate?.alpha ?? undefined,
        gy: event.rotationRate?.beta ?? undefined,
        gz: event.rotationRate?.gamma ?? undefined
      };

      pendingSamplesRef.current.push(sample);
      setCurrentMagnitude(Math.sqrt(sample.ax ** 2 + sample.ay ** 2 + sample.az ** 2));
    };

    window.addEventListener("devicemotion", handleMotion);
    return () => window.removeEventListener("devicemotion", handleMotion);
  }, [isPlaying, sensorEnabled]);

  useEffect(() => {
    const interval = window.setInterval(() => {
      void flushMotion();
    }, 3000);
    return () => window.clearInterval(interval);
  }, [flushMotion]);

  async function enableSensor() {
    if (!("DeviceMotionEvent" in window)) {
      setSensorEnabled(false);
      return;
    }

    const MotionEvent = DeviceMotionEvent as typeof DeviceMotionEvent & {
      requestPermission?: () => Promise<"granted" | "denied">;
    };
    if (typeof MotionEvent.requestPermission === "function") {
      const result = await MotionEvent.requestPermission();
      setSensorEnabled(result === "granted");
      return;
    }
    setSensorEnabled(true);
  }

  function startTrack() {
    if (isPlaying) {
      return;
    }

    const AudioContextClass = window.AudioContext ?? (window as unknown as { webkitAudioContext: AudioContextCtor }).webkitAudioContext;
    const context = new AudioContextClass();
    audioContextRef.current = context;
    scheduleDemoTrack(context, song);
    const startedAt = performance.now() - currentTimeRef.current * 1000;

    timerRef.current = window.setInterval(() => {
      const elapsed = Math.min(song.durationSec, (performance.now() - startedAt) / 1000);
      currentTimeRef.current = elapsed;
      setCurrentTime(elapsed);

      if (elapsed >= song.durationSec) {
        void finishSession();
      }
    }, 100);

    setIsPlaying(true);
  }

  async function pauseTrack() {
    stopAudio();
    setIsPlaying(false);
    await flushMotion();
  }

  async function resetTrack() {
    stopAudio();
    pendingSamplesRef.current = [];
    currentTimeRef.current = 0;
    setCurrentTime(0);
    setCurrentMagnitude(0);
    setIsPlaying(false);
  }

  async function finishSession() {
    stopAudio();
    setIsPlaying(false);
    await flushMotion();
    await fetch(`/api/collect/session/${sessionId}`, { method: "PATCH" });
    router.push(`/collect/review/${sessionId}`);
  }

  async function addLabel(config: (typeof LABEL_CONFIGS)[number]) {
    const time = currentTimeRef.current;
    const payload = {
      sessionId,
      label: config.label,
      startedAtSec: roundTime(Math.max(0, time - config.beforeSec)),
      endedAtSec: roundTime(Math.min(song.durationSec, time + config.afterSec)),
      source: "realtime_button"
    };
    const response = await fetch("/api/collect/label", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(payload)
    });
    const data = await response.json();
    setSavedLabels((labels) => [...labels, data.label]);
    setLastLabelName(config.name);
  }

  function stopAudio() {
    if (timerRef.current !== null) {
      window.clearInterval(timerRef.current);
      timerRef.current = null;
    }
    void audioContextRef.current?.close();
    audioContextRef.current = null;
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
        <h1>{song.title}</h1>
        <p>迷ったら押さなくてOK。押した内容はレビュー画面で直せます。</p>
      </section>

      <section className="panel">
        <div className="panelHeader">
          <h2>セッション</h2>
          <div className="statusRow">
            <span className="statusPill">
              <Activity size={15} /> {sensorEnabled ? "センサー取得中" : "タップのみ可"}
            </span>
            <span className="statusPill">
              <Gauge size={15} /> {currentMagnitude.toFixed(2)}
            </span>
          </div>
        </div>
        <div className="panelBody formGrid">
          <div className="transport">
            <div className="timeDisplay">
              {formatTime(currentTime)} / {formatTime(song.durationSec)}
            </div>
            <div className="statusRow">
              <button className="secondaryButton" onClick={enableSensor} type="button">
                <Activity size={18} />
                センサー
              </button>
              <button className="iconButton" onClick={isPlaying ? pauseTrack : startTrack} type="button" aria-label={isPlaying ? "一時停止" : "再生"}>
                {isPlaying ? <Pause size={20} /> : <Play size={20} />}
              </button>
              <button className="iconButton" onClick={resetTrack} type="button" aria-label="リセット">
                <RotateCcw size={20} />
              </button>
              <button className="secondaryButton" onClick={finishSession} type="button">
                <CircleStop size={18} />
                終了
              </button>
            </div>
          </div>
          <div className="timebar" aria-hidden="true">
            <div className="timebarFill" style={{ width: `${progress}%` }} />
          </div>
        </div>
      </section>

      <section className="section">
        <div className="labelGrid">
          {LABEL_CONFIGS.map((config) => (
            <button
              className={`labelButton ${config.className}`}
              key={config.label}
              onClick={() => addLabel(config)}
              type="button"
            >
              <config.Icon size={28} strokeWidth={2.2} />
              <span>
                <strong>{config.name}</strong>
                <span>{config.shortHint}</span>
              </span>
            </button>
          ))}
        </div>
      </section>

      <section className="metricGrid">
        <div className="metric">
          <span className="metricValue">{savedLabels.length}</span>
          <span className="metricLabel">labels</span>
        </div>
        <div className="metric">
          <span className="metricValue">{pendingSamplesRef.current.length}</span>
          <span className="metricLabel">pending samples</span>
        </div>
        <div className="metric">
          <span className="metricValue">{lastLabelName}</span>
          <span className="metricLabel">last label</span>
        </div>
        <div className="metric">
          <button className="primaryButton" onClick={finishSession} type="button">
            <Save size={18} />
            レビューへ
          </button>
        </div>
      </section>
    </main>
  );
}

function scheduleDemoTrack(context: AudioContext, song: DemoSong) {
  const startAt = context.currentTime + 0.06;
  const beatSec = 60 / song.bpm;

  for (let beat = 0; beat * beatSec < song.durationSec; beat += 1) {
    const time = startAt + beat * beatSec;
    const isDownbeat = beat % 4 === 0;
    const isBackbeat = beat % 4 === 2;
    const intensity =
      song.pattern === "hype" && beat * beatSec > 20 && beat * beatSec < 42 ? 1.35 : 1;

    pulse(context, time, isDownbeat ? 88 : 132, 0.08, 0.13 * intensity);
    if (isBackbeat) {
      pulse(context, time + 0.02, 220, 0.05, 0.06 * intensity);
    }

    if (song.pattern !== "chill") {
      pulse(context, time + beatSec / 2, 420, 0.035, 0.035 * intensity);
    }

    if (song.pattern === "hype" && beat % 16 === 15) {
      pulse(context, time + beatSec * 0.75, 720, 0.16, 0.08);
    }
  }
}

function pulse(
  context: AudioContext,
  time: number,
  frequency: number,
  duration: number,
  volume: number
) {
  const oscillator = context.createOscillator();
  const gain = context.createGain();
  oscillator.type = frequency > 400 ? "triangle" : "sine";
  oscillator.frequency.setValueAtTime(frequency, time);
  gain.gain.setValueAtTime(volume, time);
  gain.gain.exponentialRampToValueAtTime(0.001, time + duration);
  oscillator.connect(gain).connect(context.destination);
  oscillator.start(time);
  oscillator.stop(time + duration);
}

function formatTime(value: number): string {
  const minutes = Math.floor(value / 60);
  const seconds = Math.floor(value % 60);
  return `${minutes}:${seconds.toString().padStart(2, "0")}`;
}

function roundTime(value: number): number {
  return Math.round(value * 1000) / 1000;
}
