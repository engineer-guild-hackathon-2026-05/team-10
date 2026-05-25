const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { createSession, getSession, upsertChatSession, saveHowCard } = require('../repositories/firestore');
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
router.post('/:id/chat', auth, async (req, res) => {
  const { startTime, tags, intensity, lyric, history = [] } = req.body;
  const sessionId = req.params.id;

  if (!isValidSessionId(sessionId)) {
    return res.status(400).json({ error: 'sessionId が不正です' });
  }

  if (typeof startTime !== 'number' || !Array.isArray(tags) || typeof intensity !== 'number' || !Array.isArray(history)) {
    return res.status(400).json({ error: 'startTime, tags, intensity, history が必要です' });
  }

  try {
    await upsertChatSession({
      sessionId,
      uid: req.uid,
      startTime,
      tags,
      intensity,
      lyric,
      history,
    });
    const result = await chat({ startTime, tags, intensity, lyric, history });
    res.json(result);
  } catch (err) {
    if (err.code === 'session-forbidden') {
      return res.status(403).json({ error: err.message });
    }

    console.error(err?.message ?? err);
    res.status(500).json({ error: 'AI応答に失敗しました' });
  }
});

// POST /sessions/:id/how-card
router.post('/:id/how-card', auth, async (req, res) => {
  const { reactions, chatHistory, songTitle } = req.body;
  if (!Array.isArray(reactions) || !Array.isArray(chatHistory) || !songTitle) {
    return res.status(400).json({ error: 'reactions, chatHistory, songTitle が必要です' });
  }

  const sessionId = req.params.id;
  if (!isValidSessionId(sessionId)) {
    return res.status(400).json({ error: 'sessionId が不正です' });
  }

  const session = await getSession(sessionId);
  if (!session) {
    return res.status(404).json({ error: 'セッションが見つかりません' });
  }
  if (session.userId !== req.uid) {
    return res.status(403).json({ error: 'このセッションへのアクセス権がありません' });
  }

  try {
    const howCardData = await generateHowCard({ reactions, chatHistory, songTitle });
    const cardId = await saveHowCard({
      uid: req.uid,
      email: req.email,
      displayName: req.displayName,
      sessionId,
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

function isValidSessionId(value) {
  return typeof value === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(value);
}
