const admin = require('firebase-admin');

const db = () => admin.firestore();
const { FieldValue } = admin.firestore;

async function createSession({ uid, songTitle, durationSec, reactions }) {
  const ref = db().collection('sessions').doc();
  await ref.set({
    userId: uid,
    songTitle,
    durationSec,
    reactions,
    chatHistory: [],
    status: 'analyzing',
    createdAt: FieldValue.serverTimestamp(),
  });
  return ref.id;
}

async function getSession(sessionId) {
  const doc = await db().collection('sessions').doc(sessionId).get();
  if (!doc.exists) return null;
  return { id: doc.id, ...doc.data() };
}

async function saveHowCard({ uid, sessionId, songTitle, howTags, tagLabel, description, highlightSec }) {
  const ref = db().collection('how-cards').doc();
  await ref.set({
    userId: uid,
    sessionId,
    songTitle,
    howTags,
    tagLabel,
    description,
    highlightSec,
    createdAt: FieldValue.serverTimestamp(),
  });
  await db().collection('sessions').doc(sessionId).update({ status: 'done' });
  await db().collection('users').doc(uid).set(
    { howTags: FieldValue.arrayUnion(...howTags) },
    { merge: true }
  );
  return ref.id;
}

async function getHowCardsByTag(tag) {
  const snapshot = await db()
    .collection('how-cards')
    .where('howTags', 'array-contains', tag)
    .orderBy('createdAt', 'desc')
    .limit(50)
    .get();
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
}

module.exports = { createSession, getSession, saveHowCard, getHowCardsByTag };
