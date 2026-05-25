const admin = require('firebase-admin');

const db = () => admin.firestore();
const { FieldValue } = admin.firestore;

async function createHowCard({ uid, comment, songStart, songEnd, songId, artistId }) {
  const ref = db().collection('how-cards').doc();
  await ref.set({
    userId: uid,
    comment,
    songStart,
    songEnd,
    songId,
    artistId,
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
  const likeRef = cardRef.collection('liked-by').doc(uid);

  return db().runTransaction(async (tx) => {
    const cardDoc = await tx.get(cardRef);
    if (!cardDoc.exists) return null;

    const likeDoc = await tx.get(likeRef);
    const currentLikes = cardDoc.data().likes ?? 0;
    if (likeDoc.exists) return currentLikes;

    tx.set(likeRef, { likedAt: FieldValue.serverTimestamp() });
    tx.update(cardRef, { likes: FieldValue.increment(1) });
    return currentLikes + 1;
  });
}

module.exports = { createHowCard, getHowCards, likeHowCard };
