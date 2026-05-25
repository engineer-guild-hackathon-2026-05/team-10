const MUSIC_KIT_SONG_ID_PATTERN = /^\d{1,32}$/;

function normalizeMusicKitSongId(value) {
  if (typeof value !== 'string') return null;

  const trimmed = value.trim();
  if (!isMusicKitSongId(trimmed)) return null;
  return trimmed;
}

function isMusicKitSongId(value) {
  return typeof value === 'string' && MUSIC_KIT_SONG_ID_PATTERN.test(value);
}

module.exports = {
  normalizeMusicKitSongId,
  isMusicKitSongId,
};
