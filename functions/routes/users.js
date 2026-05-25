const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { upsertUserProfile, getUserProfile } = require('../repositories/firestore');

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

router.put('/me', auth, async (req, res) => {
  const displayName = normalizeDisplayName(req.body?.display_name ?? req.displayName);
  const tokenEmail = normalizeEmail(req.email);
  const requestedEmail = normalizeEmail(req.body?.email);
  if (tokenEmail && requestedEmail && tokenEmail !== requestedEmail) {
    return res.status(400).json({ error: 'email が認証情報と一致しません' });
  }

  const email = tokenEmail ?? null;

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
