const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { createHowCard, getHowCards, likeHowCard } = require('../repositories/firestore');

// GET /how-cards
router.get('/', auth, async (_req, res) => {
  try {
    const howCards = await getHowCards();
    res.json({ howCards });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'Howカードの取得に失敗しました' });
  }
});

// POST /how-cards
router.post('/', auth, async (req, res) => {
  const { comment, songStart, songEnd, songId, artistId } = req.body;

  if (typeof comment !== 'string' || !comment.trim()) {
    return res.status(400).json({ error: 'comment が必要です' });
  }
  if (typeof songStart !== 'number' || typeof songEnd !== 'number') {
    return res.status(400).json({ error: 'songStart, songEnd は数値で指定してください' });
  }
  if (songStart < 0 || songEnd <= songStart) {
    return res.status(400).json({ error: 'songStart, songEnd の範囲が不正です' });
  }
  if (typeof songId !== 'string' || !songId.trim()) {
    return res.status(400).json({ error: 'songId が必要です' });
  }
  if (typeof artistId !== 'string' || !artistId.trim()) {
    return res.status(400).json({ error: 'artistId が必要です' });
  }

  try {
    const trimmedComment = comment.trim();
    const trimmedSongId = songId.trim();
    const trimmedArtistId = artistId.trim();
    const cardId = await createHowCard({
      uid: req.uid,
      comment: trimmedComment,
      songStart,
      songEnd,
      songId: trimmedSongId,
      artistId: trimmedArtistId,
    });
    res.json({
      howCard: {
        id: cardId,
        userId: req.uid,
        comment: trimmedComment,
        songStart,
        songEnd,
        songId: trimmedSongId,
        artistId: trimmedArtistId,
        likes: 0,
      },
    });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'Howカードの作成に失敗しました' });
  }
});

// POST /how-cards/:id/like
router.post('/:id/like', auth, async (req, res) => {
  try {
    const likes = await likeHowCard({ cardId: req.params.id, uid: req.uid });
    if (likes === null) {
      return res.status(404).json({ error: 'Howカードが見つかりません' });
    }
    res.json({ likes });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'いいねに失敗しました' });
  }
});

module.exports = router;
