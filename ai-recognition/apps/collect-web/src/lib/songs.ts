export type DemoSong = {
  id: string;
  title: string;
  description: string;
  bpm: number;
  durationSec: number;
  pattern: "groove" | "hype" | "chill";
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
    id: "hype-demo",
    title: "Hype Drop Track",
    description: "BPM 126 / 展開変化、ドロップ、刺さりを集める",
    bpm: 126,
    durationSec: 60,
    pattern: "hype"
  },
  {
    id: "chill-demo",
    title: "Chill Afterglow Track",
    description: "BPM 76 / チル、没入、余韻を集める",
    bpm: 76,
    durationSec: 60,
    pattern: "chill"
  }
];

export function getDemoSong(songId: string): DemoSong {
  return DEMO_SONGS.find((song) => song.id === songId) ?? DEMO_SONGS[0]!;
}
