const admin = require('firebase-admin');

const db = () => admin.firestore();
const { FieldValue } = admin.firestore;

async function createHowCard({ uid, comment, songStart, songEnd, songTitle }) {
  const ref = db().collection('how-cards').doc();
  await ref.set({
    userId: uid,
    comment,
    songStart,
    songEnd,
    songTitle,
    likes: 0,
    createdAt: FieldValue.serverTimestamp(),
  });
  return ref.id;
}

async function getHowCards({ limit = 50 } = {}) {
  const snapshot = await db()
    .collection('how-cards')
    .orderBy('createdAt', 'desc')
    .limit(limit)
    .get();
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
}

async function likeHowCard({ cardId, uid }) {
  const cardRef = db().collection('how-cards').doc(cardId);
  const cardDoc = await cardRef.get();
  if (!cardDoc.exists) return null;

  const likeRef = cardRef.collection('liked-by').doc(uid);
  const existing = await likeRef.get();
  const currentLikes = cardDoc.data().likes ?? 0;
  if (existing.exists) {
    return currentLikes;
  }

  const batch = db().batch();
  batch.set(likeRef, { likedAt: FieldValue.serverTimestamp() });
  batch.update(cardRef, { likes: FieldValue.increment(1) });
  await batch.commit();

  return currentLikes + 1;
}

module.exports = { createHowCard, getHowCards, likeHowCard };
