const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { upsertUserProfile, getUserProfile } = require('../repositories/firestore');

// GET /users/me
router.get('/me', auth, async (req, res) => {
  try {
    const user = await getUserProfile(req.uid);
    if (!user) {
      return res.status(404).json({ error: 'ユーザーが見つかりません' });
    }

    res.json({ user });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'ユーザー情報の取得に失敗しました' });
  }
});

// PUT /users/me
router.put('/me', auth, async (req, res) => {
  const displayName = normalizeDisplayName(req.body?.display_name ?? req.displayName);
  const email = normalizeEmail(req.body?.email ?? req.email);
  if (!email) {
    return res.status(400).json({ error: 'email が必要です' });
  }

  try {
    const user = await upsertUserProfile({
      uid: req.uid,
      email,
      displayName,
    });
    res.json({ user });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'ユーザー情報の保存に失敗しました' });
  }
});

function normalizeEmail(value) {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed ? trimmed : null;
}

function normalizeDisplayName(value) {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed ? trimmed.slice(0, 80) : null;
}

module.exports = router;
