require('dotenv').config();
const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const app = express();
app.use(cors());
app.use(express.json());

app.use('/sessions', require('./routes/sessions'));
app.use('/how-cards', require('./routes/how-cards'));

app.get('/health', (_, res) => res.json({ status: 'ok' }));

const PORT = process.env.PORT ?? 3000;
app.listen(PORT, () => console.log(`backend listening on :${PORT}`));
