const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');

admin.initializeApp();

const anthropicKey = defineSecret('ANTHROPIC_API_KEY');

exports.api = onRequest(
  {
    region: 'asia-northeast1',
    cors: true,
    memory: '256MiB',
    timeoutSeconds: 60,
    minInstances: 1,
    secrets: [anthropicKey],
  },
  require('./app')
);
