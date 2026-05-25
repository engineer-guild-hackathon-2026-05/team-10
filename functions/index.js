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
    const userRef = admin.firestore().collection('users').doc(user.uid);
    try {
      await userRef.create({
        email: user.email ?? null,
        displayName: user.displayName ?? null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (err) {
      // grpc code 6 = ALREADY_EXISTS. Trigger re-fired, user doc already created — no-op.
      if (err.code !== 6) throw err;
    }
  });
