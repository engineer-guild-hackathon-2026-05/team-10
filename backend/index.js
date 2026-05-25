require('dotenv').config();
const fs = require('fs');
const path = require('path');
const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');

const KEY_PATH = path.join(__dirname, 'serviceAccountKey.json');
if (fs.existsSync(KEY_PATH)) {
  admin.initializeApp({ credential: admin.credential.cert(require(KEY_PATH)) });
} else {
  // Use GOOGLE_APPLICATION_CREDENTIALS env var or platform-provided ADC
  admin.initializeApp({ credential: admin.credential.applicationDefault() });
}

const corsOrigin = process.env.CORS_ORIGIN
  ? process.env.CORS_ORIGIN.split(',').map(origin => origin.trim()).filter(Boolean)
  : true;

const app = express();
app.use(cors({ origin: corsOrigin }));
app.use(express.json({ limit: '1mb' }));

app.use('/sessions', require('./routes/sessions'));
app.use('/how-cards', require('./routes/how-cards'));
app.use('/users', require('./routes/users'));

app.get('/health', (_, res) => res.json({ status: 'ok' }));

app.use((err, _req, res, _next) => {
  console.error(err?.message ?? err);
  res.status(500).json({ error: 'サーバーエラー' });
});

const PORT = process.env.PORT ?? 3000;
app.listen(PORT, () => console.log(`backend listening on :${PORT}`));
