const admin = require('firebase-admin');

const db = () => admin.firestore();
const { FieldValue } = admin.firestore;

async function createHowCard({ uid, comment, songStart, songEnd, songId, artistId }) {
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

async function updateHowCard({ uid, cardId, comment, songStart, songEnd, songId, artistId }) {
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

    transaction.update(ref, {
      comment,
      song_start: songStart,
      song_end: songEnd,
      song_id: songId,
      artist_id: artistId,
      updated_at: FieldValue.serverTimestamp(),
    });
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
    const currentGoods = currentGoodsCount(data);
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

async function getUserProfiles(userIds) {
  const uniqueUserIds = uniqueNonEmptyStrings(userIds);
  if (uniqueUserIds.length === 0) return [];

  const refs = uniqueUserIds.map(uid => db().collection('users').doc(uid));
  const snapshots = await db().getAll(...refs);
  return snapshots
    .filter(snapshot => snapshot.exists)
    .map(snapshot => serializeUser(snapshot.id, snapshot.data()))
    .filter(Boolean);
}

async function seedUserProfiles({ users }) {
  const normalizedUsers = uniqueUsers(users);
  if (normalizedUsers.length === 0) return [];

  const refs = normalizedUsers.map(user => db().collection('users').doc(user.userId));
  const snapshots = await db().getAll(...refs);
  const batch = db().batch();
  const now = FieldValue.serverTimestamp();

  snapshots.forEach((snapshot, index) => {
    const seedUser = normalizedUsers[index];
    const existingData = snapshot.exists ? snapshot.data() : {};
    const data = {
      user_id: seedUser.userId,
      updated_at: now,
    };

    if (!snapshot.exists || !isNonEmptyString(existingData.display_name)) {
      data.display_name = seedUser.displayName;
    }

    if (isNonEmptyString(seedUser.email) && (!snapshot.exists || !isNonEmptyString(existingData.email))) {
      data.email = seedUser.email;
    }

    if (!snapshot.exists || !isFirestoreTimestamp(existingData.created_at)) {
      data.created_at = now;
    }

    batch.set(refs[index], data, { merge: true });
  });

  await batch.commit();
  return getUserProfiles(normalizedUsers.map(user => user.userId));
}

function serializeHowCard(id, data) {
  if (!isHowCardComment(data)) return null;

  return {
    id,
    comment: data.comment,
    song_start: Number.isFinite(data.song_start) ? data.song_start : 0,
    song_end: Number.isFinite(data.song_end) ? data.song_end : 0,
    song_id: data.song_id,
    artist_id: data.artist_id,
    user_id: data.user_id,
    goods: currentGoodsCount(data),
    likes: currentGoodsCount(data),
    created_at: timestampToISOString(data.created_at),
    updated_at: timestampToISOString(data.updated_at),
  };
}

function currentGoodsCount(data) {
  if (Number.isInteger(data.goods)) return data.goods;
  if (Number.isInteger(data.likes)) return data.likes;
  return 0;
}

function serializeUser(id, data = {}) {
  return {
    id,
    user_id: data.user_id ?? id,
    email: data.email ?? null,
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

function isNonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function uniqueNonEmptyStrings(values) {
  const seen = new Set();
  for (const value of values ?? []) {
    if (!isNonEmptyString(value)) continue;
    seen.add(value.trim());
  }
  return [...seen];
}

function uniqueUsers(users) {
  const seen = new Map();
  for (const user of users ?? []) {
    if (!user || !isNonEmptyString(user.userId) || !isNonEmptyString(user.displayName)) continue;

    const userId = user.userId.trim();
    if (seen.has(userId)) continue;

    seen.set(userId, {
      userId,
      email: isNonEmptyString(user.email) ? user.email.trim() : null,
      displayName: user.displayName.trim().slice(0, 80),
    });
  }
  return [...seen.values()];
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
  getUserProfiles,
  seedUserProfiles,
};
