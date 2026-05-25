const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { createSession, getSession, saveHowCard } = require('../repositories/firestore');
const { chat, generateHowCard } = require('../services/claude');

// POST /sessions
router.post('/', auth, async (req, res) => {
  const { songTitle, durationSec, reactions } = req.body;
  if (!songTitle || typeof durationSec !== 'number' || !Array.isArray(reactions)) {
    return res.status(400).json({ error: 'songTitle, durationSec, reactions が必要です' });
  }
  try {
    const sessionId = await createSession({ uid: req.uid, songTitle, durationSec, reactions });
    res.json({ sessionId });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'セッションの保存に失敗しました' });
  }
});

// POST /sessions/:id/chat
router.post('/:id/chat', async (req, res) => {
  const { startTime, tags, intensity, lyric, history = [] } = req.body;
  try {
    const result = await chat({ startTime, tags, intensity, lyric, history });
    res.json(result);
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'AI応答に失敗しました' });
  }
});

// POST /sessions/:id/how-card
// TODO: デモ後に auth ミドルウェアを戻す (#35)
router.post('/:id/how-card', async (req, res) => {
  const { reactions, chatHistory, songTitle } = req.body;
  if (!Array.isArray(reactions) || !Array.isArray(chatHistory) || !songTitle) {
    return res.status(400).json({ error: 'reactions, chatHistory, songTitle が必要です' });
  }
  try {
    const howCardData = await generateHowCard({ reactions, chatHistory, songTitle });
    const cardId = await saveHowCard({
      uid: 'anonymous',
      sessionId: req.params.id,
      songTitle,
      ...howCardData,
    });
    console.log('[how-card] Firestore saved:', cardId);
    res.json({ howCard: { id: cardId, ...howCardData } });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'Howカードの生成に失敗しました' });
  }
});

module.exports = router;
