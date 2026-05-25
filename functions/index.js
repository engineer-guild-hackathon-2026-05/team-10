const { onRequest } = require('firebase-functions/v2/https');
const functionsV1 = require('firebase-functions/v1');
const admin = require('firebase-admin');

admin.initializeApp();

exports.api = onRequest(
  {
    region: 'asia-northeast1',
    cors: true,
    memory: '256MiB',
    timeoutSeconds: 60,
    minInstances: 1,
  },
  require('./app')
);

exports.onUserSignup = functionsV1
  .region('asia-northeast1')
  .auth.user()
  .onCreate(async (user) => {
    await admin.firestore().collection('users').doc(user.uid).set({
      email: user.email ?? null,
      displayName: user.displayName ?? null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
