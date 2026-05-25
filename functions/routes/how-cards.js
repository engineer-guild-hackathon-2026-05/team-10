const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const {
  createHowCardComment,
  updateHowCardComment,
  getHowCardComment,
  getHowCardCommentsBySong,
  incrementHowCardGoods,
  getHowCardsByTag,
} = require('../repositories/firestore');

// GET /how-cards?song_id=1704093812
// GET /how-cards?tag=groove (legacy generated-card search)
router.get('/', auth, async (req, res) => {
  const { song_id: songId, tag } = req.query;

  try {
    if (songId) {
      const howCards = await getHowCardCommentsBySong(String(songId), parseLimit(req.query.limit));
      res.json({ howCards });
      return;
    }

    if (!tag) {
      return res.status(400).json({ error: 'song_id または tag パラメータが必要です' });
    }

    const howCards = await getHowCardsByTag(String(tag));
    res.json({ howCards });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'Howカードの取得に失敗しました' });
  }
});

// GET /how-cards/:id
router.get('/:id', auth, async (req, res) => {
  try {
    const howCard = await getHowCardComment(req.params.id);
    if (!howCard) {
      return res.status(404).json({ error: 'Howカードが見つかりません' });
    }

    res.json({ howCard });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'Howカードの取得に失敗しました' });
  }
});

// POST /how-cards
router.post('/', auth, async (req, res) => {
  const payload = normalizeCommentPayload(req.body);
  if (!payload) {
    return res.status(400).json({ error: 'comment, song_start, song_end, song_id, artist_id が必要です' });
  }

  try {
    const howCard = await createHowCardComment({ uid: req.uid, ...payload });
    res.status(201).json({ howCard });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'Howカードの作成に失敗しました' });
  }
});

// PATCH /how-cards/:id
router.patch('/:id', auth, async (req, res) => {
  const payload = normalizeCommentPayload(req.body);
  if (!payload) {
    return res.status(400).json({ error: 'comment, song_start, song_end, song_id, artist_id が必要です' });
  }

  try {
    const howCard = await updateHowCardComment({ uid: req.uid, cardId: req.params.id, ...payload });
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

// POST /how-cards/:id/goods
router.post('/:id/goods', auth, async (req, res) => {
  try {
    const howCard = await incrementHowCardGoods(req.params.id);
    res.json({ howCard });
  } catch (err) {
    if (err.code === 'not-found') {
      return res.status(404).json({ error: err.message });
    }

    console.error(err?.message ?? err);
    res.status(500).json({ error: 'Howカードのいいね更新に失敗しました' });
  }
});

function normalizeCommentPayload(body) {
  if (!body || typeof body !== 'object') return null;

  const comment = normalizeString(body.comment, 140);
  const songStart = normalizeRangePoint(body.song_start);
  const songEnd = normalizeRangePoint(body.song_end);
  const songId = normalizeString(body.song_id, 120);
  const artistId = normalizeString(body.artist_id, 120);
  if (!comment || songStart == null || songEnd == null || songEnd < songStart || !songId || !artistId) {
    return null;
  }

  return { comment, songStart, songEnd, songId, artistId };
}

function normalizeString(value, maxLength) {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  if (!trimmed) return null;
  return trimmed.length <= maxLength ? trimmed : null;
}

function parseLimit(value) {
  const number = Number(value);
  if (!Number.isFinite(number)) return 50;
  return Math.min(100, Math.max(1, Math.floor(number)));
}

function normalizeRangePoint(value) {
  const number = Number(value);
  if (!Number.isFinite(number) || number < 0) return null;
  return number;
}

module.exports = router;
