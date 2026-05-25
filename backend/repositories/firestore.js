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

async function saveHowCard({
  uid,
  email,
  displayName,
  sessionId,
  songTitle,
  howTags,
  tagLabel,
  description,
  highlightSec,
}) {
  const cardRef = db().collection('how-cards').doc();
  const sessionRef = db().collection('sessions').doc(sessionId);
  const userRef = db().collection('users').doc(uid);

  const batch = db().batch();

  batch.set(cardRef, {
    userId: uid,
    displayName: displayName ?? null,
    sessionId,
    songTitle,
    howTags,
    tagLabel,
    description,
    highlightSec,
    createdAt: FieldValue.serverTimestamp(),
  });

  batch.set(sessionRef, { status: 'done' }, { merge: true });

  const userUpdate = {};
  if (email) userUpdate.email = email;
  if (displayName) userUpdate.displayName = displayName;
  if (howTags.length > 0) userUpdate.howTags = FieldValue.arrayUnion(...howTags);
  if (Object.keys(userUpdate).length > 0) {
    userUpdate.updatedAt = FieldValue.serverTimestamp();
    batch.set(userRef, userUpdate, { merge: true });
  }

  await batch.commit();
  return cardRef.id;
}

async function upsertUserProfile({ uid, email, displayName }) {
  const userRef = db().collection('users').doc(uid);
  const now = FieldValue.serverTimestamp();

  await db().runTransaction(async transaction => {
    const snapshot = await transaction.get(userRef);
    const existingData = snapshot.exists ? snapshot.data() : {};
    const data = {
      user_id: uid,
      email,
      display_name: displayName ?? null,
      updated_at: now,
    };

    if (!snapshot.exists || !existingData.created_at) {
      data.created_at = existingData.createdAt ?? now;
    }

    transaction.set(userRef, data, { merge: true });
  });

  const snapshot = await userRef.get();
  return serializeUser(snapshot.id, snapshot.data());
}

async function getUserProfile(uid) {
  const doc = await db().collection('users').doc(uid).get();
  if (!doc.exists) return null;
  return serializeUser(doc.id, doc.data());
}

async function createHowCardComment({ uid, comment, songStart, songEnd, songId, artistId }) {
  const ref = db().collection('how-cards').doc();
  const data = {
    comment,
    song_start: songStart,
    song_end: songEnd,
    song_id: songId,
    artist_id: artistId,
    user_id: uid,
    goods: 0,
  };

  await ref.set(data);
  return { id: ref.id, ...data };
}

async function updateHowCardComment({ uid, cardId, comment, songStart, songEnd, songId, artistId }) {
  const ref = db().collection('how-cards').doc(cardId);

  await db().runTransaction(async transaction => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) {
      const error = new Error('Howカードが見つかりません');
      error.code = 'not-found';
      throw error;
    }

    const data = snapshot.data();
    if (data.user_id !== uid) {
      const error = new Error('このHowカードへのアクセス権がありません');
      error.code = 'permission-denied';
      throw error;
    }

    transaction.update(ref, {
      comment,
      song_start: songStart,
      song_end: songEnd,
      song_id: songId,
      artist_id: artistId,
    });
  });

  const updated = await ref.get();
  return serializeHowCardComment(updated.id, updated.data());
}

async function getHowCardComment(cardId) {
  const doc = await db().collection('how-cards').doc(cardId).get();
  if (!doc.exists) return null;
  return serializeHowCardComment(doc.id, doc.data());
}

async function getHowCardCommentsBySong(songId, limit = 50) {
  const snapshot = await db()
    .collection('how-cards')
    .where('song_id', '==', songId)
    .limit(limit)
    .get();
  return snapshot.docs
    .map(doc => serializeHowCardComment(doc.id, doc.data()))
    .filter(Boolean);
}

async function incrementHowCardGoods(cardId) {
  const ref = db().collection('how-cards').doc(cardId);

  await db().runTransaction(async transaction => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) {
      const error = new Error('Howカードが見つかりません');
      error.code = 'not-found';
      throw error;
    }

    if (typeof snapshot.data().comment !== 'string') {
      const error = new Error('Howカードが見つかりません');
      error.code = 'not-found';
      throw error;
    }

    transaction.update(ref, { goods: FieldValue.increment(1) });
  });

  const updated = await ref.get();
  return serializeHowCardComment(updated.id, updated.data());
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

function serializeHowCardComment(id, data) {
  if (!data || typeof data.comment !== 'string') return null;

  return {
    id,
    comment: data.comment,
    song_start: Number.isFinite(data.song_start) ? data.song_start : 0,
    song_end: Number.isFinite(data.song_end) ? data.song_end : 0,
    song_id: data.song_id,
    artist_id: data.artist_id,
    user_id: data.user_id,
    goods: Number.isInteger(data.goods) ? data.goods : 0,
  };
}

function serializeUser(id, data) {
  return {
    id,
    user_id: data.user_id ?? id,
    email: data.email,
    display_name: data.display_name ?? data.displayName ?? null,
    created_at: timestampToISOString(data.created_at ?? data.createdAt),
    updated_at: timestampToISOString(data.updated_at ?? data.updatedAt),
  };
}

function timestampToISOString(value) {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  return null;
}

module.exports = {
  createSession,
  getSession,
  saveHowCard,
  upsertUserProfile,
  getUserProfile,
  createHowCardComment,
  updateHowCardComment,
  getHowCardComment,
  getHowCardCommentsBySong,
  incrementHowCardGoods,
  getHowCardsByTag,
};
