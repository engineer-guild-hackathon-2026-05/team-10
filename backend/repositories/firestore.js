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
  const cardRef = db().collection('how-cards').doc();
  const sessionRef = db().collection('sessions').doc(sessionId);
  const userRef = db().collection('users').doc(uid);

  const batch = db().batch();

  batch.set(cardRef, {
    userId: uid,
    sessionId,
    songTitle,
    howTags,
    tagLabel,
    description,
    highlightSec,
    createdAt: FieldValue.serverTimestamp(),
  });

  batch.set(sessionRef, { status: 'done' }, { merge: true });

  if (howTags.length > 0) {
    batch.set(
      userRef,
      { howTags: FieldValue.arrayUnion(...howTags) },
      { merge: true }
    );
  }

  await batch.commit();
  return cardRef.id;
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
