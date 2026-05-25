const admin = require('firebase-admin');

const db = () => admin.firestore();
const { FieldValue } = admin.firestore;

async function createHowCard({ uid, comment, songStart, songEnd, songId, artistId, itunesId, songSlug }) {
  const ref = db().collection('how-cards').doc();
  const data = {
    comment,
    song_start: songStart,
    song_end: songEnd,
    song_id: songId,
    itunes_id: itunesId ?? songId,
    artist_id: artistId,
    user_id: uid,
    likes: 0,
    created_at: FieldValue.serverTimestamp(),
  };

  if (songSlug) data.song_slug = songSlug;

  await ref.set(data);
  return serializeHowCard(ref.id, { ...data, created_at: null });
}

async function getHowCards({ songId, limit = 50 } = {}) {
  let query = db().collection('how-cards');

  if (songId) {
    query = query.where('song_id', '==', songId).orderBy('created_at', 'desc');
  } else {
    query = query.orderBy('created_at', 'desc');
  }

  const snapshot = await query.limit(limit).get();
  return snapshot.docs
    .map(doc => serializeHowCard(doc.id, doc.data()))
    .filter(Boolean);
}

async function getHowCard(cardId) {
  const doc = await db().collection('how-cards').doc(cardId).get();
  if (!doc.exists) return null;
  return serializeHowCard(doc.id, doc.data());
}

async function updateHowCard({ uid, cardId, comment, songStart, songEnd, songId, artistId, itunesId, songSlug }) {
  const ref = db().collection('how-cards').doc(cardId);

  await db().runTransaction(async transaction => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) {
      throwFirestoreError('Howカードが見つかりません', 'not-found');
    }

    const data = snapshot.data();
    if (!isHowCardComment(data)) {
      throwFirestoreError('Howカードが見つかりません', 'not-found');
    }

    if (data.user_id !== uid) {
      throwFirestoreError('このHowカードへのアクセス権がありません', 'permission-denied');
    }

    const patch = {
      comment,
      song_start: songStart,
      song_end: songEnd,
      song_id: songId,
      itunes_id: itunesId ?? songId,
      artist_id: artistId,
      updated_at: FieldValue.serverTimestamp(),
    };
    if (songSlug) {
      patch.song_slug = songSlug;
    } else {
      patch.song_slug = FieldValue.delete();
    }

    transaction.update(ref, patch);
  });

  return getHowCard(cardId);
}

async function likeHowCard({ cardId, uid }) {
  const cardRef = db().collection('how-cards').doc(cardId);
  const likeRef = cardRef.collection('liked-by').doc(uid);

  return db().runTransaction(async transaction => {
    const cardDoc = await transaction.get(cardRef);
    if (!cardDoc.exists) return null;

    const data = cardDoc.data();
    if (!isHowCardComment(data)) return null;

    const likeDoc = await transaction.get(likeRef);
    const currentLikes = Number.isInteger(data.likes) ? data.likes : 0;
    if (likeDoc.exists) return currentLikes;

    transaction.set(likeRef, {
      user_id: uid,
      liked_at: FieldValue.serverTimestamp(),
    });
    transaction.update(cardRef, {
      likes: FieldValue.increment(1),
      updated_at: FieldValue.serverTimestamp(),
    });
    return currentLikes + 1;
  });
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

function serializeHowCard(id, data) {
  if (!isHowCardComment(data)) return null;
  const songId = canonicalMusicSongID(data);
  if (!songId) return null;

  const songSlug = normalizeString(data.song_slug)
    ?? (isMusicSongID(data.song_id) ? null : normalizeString(data.song_id));

  return {
    id,
    comment: data.comment,
    song_start: Number.isFinite(data.song_start) ? data.song_start : 0,
    song_end: Number.isFinite(data.song_end) ? data.song_end : 0,
    song_id: songId,
    itunes_id: songId,
    ...(songSlug ? { song_slug: songSlug } : {}),
    artist_id: data.artist_id,
    user_id: data.user_id,
    likes: Number.isInteger(data.likes) ? data.likes : 0,
    created_at: timestampToISOString(data.created_at),
    updated_at: timestampToISOString(data.updated_at),
  };
}

function serializeUser(id, data = {}) {
  return {
    id,
    user_id: data.user_id ?? id,
    email: data.email,
    display_name: data.display_name ?? data.displayName ?? null,
    created_at: timestampToISOString(data.created_at ?? data.createdAt),
    updated_at: timestampToISOString(data.updated_at ?? data.updatedAt),
  };
}

function isHowCardComment(data) {
  return Boolean(
    data &&
      typeof data.comment === 'string' &&
      typeof data.song_id === 'string' &&
      typeof data.artist_id === 'string' &&
      typeof data.user_id === 'string'
  );
}

function canonicalMusicSongID(data) {
  return normalizeMusicSongID(data.itunes_id)
    ?? normalizeMusicSongID(data.music_kit_id)
    ?? normalizeMusicSongID(data.song_id);
}

function normalizeMusicSongID(value) {
  const text = normalizeString(value);
  if (!text || !isMusicSongID(text)) return null;
  return text;
}

function isMusicSongID(value) {
  return typeof value === 'string' && /^\d{5,}$/.test(value);
}

function normalizeString(value) {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed || null;
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

function throwFirestoreError(message, code) {
  const error = new Error(message);
  error.code = code;
  throw error;
}

module.exports = {
  createHowCard,
  getHowCards,
  getHowCard,
  updateHowCard,
  likeHowCard,
  upsertUserProfile,
  getUserProfile,
};
