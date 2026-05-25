const admin = require('firebase-admin');
const { isMusicKitSongId } = require('../utils/musicKit');

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

    if (!snapshot.exists || !isFirestoreTimestamp(existingData.created_at)) {
      data.created_at = now;
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
    created_at: FieldValue.serverTimestamp(),
  };

  await ref.set(data);
  return serializeHowCardComment(ref.id, { ...data, created_at: null });
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
    if (!isHowCardComment(data)) {
      const error = new Error('Howカードが見つかりません');
      error.code = 'not-found';
      throw error;
    }

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
      updated_at: FieldValue.serverTimestamp(),
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
    .orderBy('created_at', 'desc')
    .limit(limit)
    .get();
  return snapshot.docs
    .map(doc => serializeHowCardComment(doc.id, doc.data()))
    .filter(Boolean);
}

async function likeHowCardComment({ cardId, uid }) {
  const cardRef = db().collection('how-cards').doc(cardId);
  const likeRef = cardRef.collection('liked-by').doc(uid);

  return db().runTransaction(async transaction => {
    const cardDoc = await transaction.get(cardRef);
    if (!cardDoc.exists) return null;

    const data = cardDoc.data();
    if (!isHowCardComment(data)) return null;

    const likeDoc = await transaction.get(likeRef);
    const currentGoods = Number.isInteger(data.goods) ? data.goods : 0;
    if (likeDoc.exists) return currentGoods;

    transaction.set(likeRef, {
      user_id: uid,
      liked_at: FieldValue.serverTimestamp(),
    });
    transaction.update(cardRef, {
      goods: FieldValue.increment(1),
      updated_at: FieldValue.serverTimestamp(),
    });
    return currentGoods + 1;
  });
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
  if (!isHowCardComment(data)) return null;

  const howCard = {
    id,
    comment: data.comment,
    song_start: Number.isFinite(data.song_start) ? data.song_start : 0,
    song_end: Number.isFinite(data.song_end) ? data.song_end : 0,
    song_id: data.song_id,
    artist_id: data.artist_id,
    user_id: data.user_id,
    goods: Number.isInteger(data.goods) ? data.goods : 0,
    created_at: timestampToISOString(data.created_at),
    updated_at: timestampToISOString(data.updated_at),
  };

  if (typeof data.song_slug === 'string') {
    howCard.song_slug = data.song_slug;
  }
  if (typeof data.song_title === 'string') {
    howCard.song_title = data.song_title;
  }
  if (typeof data.artist_name === 'string') {
    howCard.artist_name = data.artist_name;
  }

  return howCard;
}

function isHowCardComment(data) {
  return Boolean(
    data &&
      typeof data.comment === 'string' &&
      typeof data.song_id === 'string' &&
      isMusicKitSongId(data.song_id) &&
      typeof data.artist_id === 'string' &&
      typeof data.user_id === 'string'
  );
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
  if (typeof value === 'string') return value;
  if (typeof value.toDate === 'function') return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  return null;
}

function isFirestoreTimestamp(value) {
  return Boolean(value && typeof value.toDate === 'function');
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
  likeHowCardComment,
  getHowCardsByTag,
};
