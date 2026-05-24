const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { getHowCardsByTag } = require('../repositories/firestore');

// GET /how-cards?tag=groove
router.get('/', auth, async (req, res) => {
  const { tag } = req.query;
  if (!tag) return res.status(400).json({ error: 'tag パラメータが必要です' });
  try {
    const howCards = await getHowCardsByTag(tag);
    res.json({ howCards });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'Howカードの取得に失敗しました' });
  }
});

module.exports = router;
