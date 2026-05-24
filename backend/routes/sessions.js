const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { createSession, saveHowCard } = require('../repositories/firestore');
const { chat, generateHowCard } = require('../services/claude');

// POST /sessions
router.post('/', auth, async (req, res) => {
  const { songTitle, durationSec, reactions } = req.body;
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
router.post('/:id/how-card', auth, async (req, res) => {
  const { reactions, chatHistory, songTitle } = req.body;
  try {
    const howCardData = await generateHowCard({ reactions, chatHistory, songTitle });
    const cardId = await saveHowCard({
      uid: req.uid,
      sessionId: req.params.id,
      songTitle,
      ...howCardData,
    });
    res.json({ howCard: { id: cardId, ...howCardData } });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'Howカードの生成に失敗しました' });
  }
});

module.exports = router;
