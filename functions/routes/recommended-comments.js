const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { getRecommendedHowCards } = require('../repositories/firestore');

router.get('/', auth, async (req, res) => {
  try {
    const comments = await getRecommendedHowCards({
      limit: parseLimit(req.query.limit),
    });
    res.json({ comments });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'おすすめコメントの取得に失敗しました' });
  }
});

function parseLimit(value) {
  const number = Number(value);
  if (!Number.isFinite(number)) return 12;
  return Math.min(50, Math.max(1, Math.floor(number)));
}

module.exports = router;
