const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const {
  createHowCard,
  getHowCards,
  getHowCard,
  updateHowCard,
  likeHowCard,
} = require('../repositories/firestore');

router.get('/', auth, async (req, res) => {
  try {
    const songId = normalizeOptionalMusicSongID(req.query.song_id);
    if (req.query.song_id != null && !songId) {
      return res.status(400).json({
        error: 'song_id は MusicKit / Apple Music / iTunes の曲 ID を指定してください',
      });
    }

    const howCards = await getHowCards({
      songId,
      limit: parseLimit(req.query.limit),
    });
    res.json({ howCards });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'Howカードの取得に失敗しました' });
  }
});

router.get('/:id', auth, async (req, res) => {
  try {
    const howCard = await getHowCard(req.params.id);
    if (!howCard) {
      return res.status(404).json({ error: 'Howカードが見つかりません' });
    }

    res.json({ howCard });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'Howカードの取得に失敗しました' });
  }
});

router.post('/', auth, async (req, res) => {
  const payload = normalizeCommentPayload(req.body);
  if (!payload) {
    return res.status(400).json({
      error: 'comment, song_start, song_end, artist_id と MusicKit / Apple Music / iTunes の song_id が必要です',
    });
  }

  try {
    const howCard = await createHowCard({ uid: req.uid, ...payload });
    res.status(201).json({ howCard });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'Howカードの作成に失敗しました' });
  }
});

router.patch('/:id', auth, async (req, res) => {
  const payload = normalizeCommentPayload(req.body);
  if (!payload) {
    return res.status(400).json({
      error: 'comment, song_start, song_end, artist_id と MusicKit / Apple Music / iTunes の song_id が必要です',
    });
  }

  try {
    const howCard = await updateHowCard({ uid: req.uid, cardId: req.params.id, ...payload });
    res.json({ howCard });
  } catch (err) {
    if (err.code === 'not-found') {
      return res.status(404).json({ error: err.message });
    }
    if (err.code === 'permission-denied') {
      return res.status(403).json({ error: err.message });
    }

    console.error(err?.message ?? err);
    res.status(500).json({ error: 'Howカードの更新に失敗しました' });
  }
});

router.post('/:id/like', auth, async (req, res) => {
  try {
    const likes = await likeHowCard({ cardId: req.params.id, uid: req.uid });
    if (likes === null) {
      return res.status(404).json({ error: 'Howカードが見つかりません' });
    }

    res.json({ likes });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'Howカードのいいね更新に失敗しました' });
  }
});

function normalizeCommentPayload(body) {
  if (!body || typeof body !== 'object') return null;

  const comment = normalizeRequiredString(body.comment, 140);
  const songStart = normalizeRangePoint(body.song_start);
  const songEnd = normalizeRangePoint(body.song_end);
  const rawSongId = normalizeRequiredString(body.song_id, 120);
  const bodyItunesId = normalizeOptionalMusicSongID(body.itunes_id);
  const bodyMusicKitId = normalizeOptionalMusicSongID(body.music_kit_id);
  const canonicalSongId = normalizeOptionalMusicSongID(rawSongId) ?? bodyItunesId ?? bodyMusicKitId;
  const artistId = normalizeRequiredString(body.artist_id, 120);
  if (!comment || songStart == null || songEnd == null || songEnd <= songStart || !canonicalSongId || !artistId) {
    return null;
  }

  const explicitSongSlug = normalizeOptionalString(body.song_slug, 120);
  const songSlug = explicitSongSlug ?? (rawSongId !== canonicalSongId ? rawSongId : null);

  return {
    comment,
    songStart,
    songEnd,
    songId: canonicalSongId,
    artistId,
    itunesId: bodyItunesId ?? bodyMusicKitId ?? canonicalSongId,
    songSlug,
  };
}

function normalizeOptionalString(value, maxLength) {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  if (!trimmed) return null;
  return trimmed.length <= maxLength ? trimmed : null;
}

function normalizeRequiredString(value, maxLength) {
  return normalizeOptionalString(value, maxLength);
}

function normalizeOptionalMusicSongID(value) {
  const trimmed = normalizeOptionalString(value, 64);
  if (!trimmed || !/^\d{5,}$/.test(trimmed)) return null;
  return trimmed;
}

function normalizeRangePoint(value) {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < 0) return null;
  return value;
}

function parseLimit(value) {
  const number = Number(value);
  if (!Number.isFinite(number)) return 50;
  return Math.min(100, Math.max(1, Math.floor(number)));
}

module.exports = router;
