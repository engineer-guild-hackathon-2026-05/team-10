export type DemoSong = {
  id: string;
  title: string;
  description: string;
  bpm: number;
  durationSec: number;
  pattern: "groove" | "chill" | "neutral";
};

export const DEMO_SONGS: DemoSong[] = [
  {
    id: "groove-demo",
    title: "Groove Track",
    description: "BPM 100 / 継続的なリズムでノリを集める",
    bpm: 100,
    durationSec: 60,
    pattern: "groove"
  },
  {
    id: "neutral-demo",
    title: "Neutral Track",
    description: "BPM 92 / 大きな反応がない聴き方を集める",
    bpm: 92,
    durationSec: 60,
    pattern: "neutral"
  },
  {
    id: "chill-demo",
    title: "Chill Track",
    description: "BPM 76 / 小さく心地よい揺れを集める",
    bpm: 76,
    durationSec: 60,
    pattern: "chill"
  }
];

export function getDemoSong(songId: string): DemoSong {
  return DEMO_SONGS.find((song) => song.id === songId) ?? DEMO_SONGS[0]!;
}
