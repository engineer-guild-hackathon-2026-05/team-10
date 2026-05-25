const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const {
  upsertUserProfile,
  getUserProfile,
  getUserProfiles,
  seedUserProfiles,
} = require('../repositories/firestore');

router.get('/', auth, async (req, res) => {
  const userIds = normalizeUserIds(req.query?.user_ids);
  if (userIds.length === 0) {
    return res.status(400).json({ error: 'user_ids が必要です' });
  }

  try {
    const users = await getUserProfiles(userIds);
    res.json({ users });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'ユーザー一覧の取得に失敗しました' });
  }
});

router.post('/seed', auth, async (req, res) => {
  const users = normalizeSeedUsers(req.body?.users);
  if (users.length === 0) {
    return res.status(400).json({ error: 'users が必要です' });
  }

  try {
    const seededUsers = await seedUserProfiles({ users });
    res.json({ users: seededUsers });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'seed ユーザー情報の保存に失敗しました' });
  }
});

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

  const email = tokenEmail;
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

function normalizeUserIds(value) {
  const rawValues = Array.isArray(value) ? value : String(value ?? '').split(',');
  const seen = new Set();

  for (const rawValue of rawValues) {
    const userId = normalizeUserId(rawValue);
    if (userId) seen.add(userId);
  }

  return [...seen].slice(0, 250);
}

function normalizeSeedUsers(value) {
  if (!Array.isArray(value)) return [];

  const seen = new Map();
  for (const rawUser of value) {
    const userId = normalizeUserId(rawUser?.user_id ?? rawUser?.userID);
    const displayName = normalizeDisplayName(rawUser?.display_name ?? rawUser?.displayName);
    if (!userId || !displayName || seen.has(userId)) continue;

    seen.set(userId, {
      userId,
      email: normalizeEmail(rawUser?.email),
      displayName,
    });
  }

  return [...seen.values()].slice(0, 250);
}

function normalizeUserId(value) {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed ? trimmed.slice(0, 128) : null;
}

module.exports = router;
