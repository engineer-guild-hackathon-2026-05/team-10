const admin = require('firebase-admin');
const { isMusicKitSongId } = require('../utils/musicKit');

const LEGACY_SONG_ID_MIGRATIONS = {
  // JP storefront Apple Music URL: https://music.apple.com/jp/song/1473069152
  'radwimps-愛にできることはまだあるかい': {
    song_id: '1473069152',
    song_slug: 'radwimps-愛にできることはまだあるかい',
    song_title: '愛にできることはまだあるかい',
    artist_name: 'RADWIMPS',
  },
};

const MAX_BATCH_WRITES = 450;

async function main() {
  const shouldWrite = process.argv.includes('--write');
  if (!admin.apps.length) {
    admin.initializeApp();
  }

  const firestore = admin.firestore();
  const snapshot = await firestore.collection('how-cards').get();
  const skipped = [];
  let batch = firestore.batch();
  let pendingWrites = 0;
  let queued = 0;
  let committed = 0;

  async function commitPendingBatch() {
    if (pendingWrites === 0) return;

    try {
      await batch.commit();
      committed += pendingWrites;
    } catch (error) {
      console.error(`failed to commit migration batch committed=${committed} pending=${pendingWrites}`);
      throw error;
    }

    batch = firestore.batch();
    pendingWrites = 0;
  }

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const currentSongId = data.song_id;

    if (typeof currentSongId !== 'string' || isMusicKitSongId(currentSongId)) {
      continue;
    }

    const migration = LEGACY_SONG_ID_MIGRATIONS[currentSongId];
    if (!migration) {
      skipped.push({ id: doc.id, song_id: currentSongId });
      continue;
    }

    if (shouldWrite) {
      batch.update(doc.ref, {
        song_id: migration.song_id,
        song_slug: typeof data.song_slug === 'string' ? data.song_slug : migration.song_slug,
        song_title: typeof data.song_title === 'string' ? data.song_title : migration.song_title,
        artist_name: typeof data.artist_name === 'string' ? data.artist_name : migration.artist_name,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      pendingWrites += 1;

      if (pendingWrites >= MAX_BATCH_WRITES) {
        await commitPendingBatch();
      }
    }

    queued += 1;
  }

  await commitPendingBatch();

  console.log(`how-cards scanned=${snapshot.size} queued=${queued} committed=${committed} skipped=${skipped.length} mode=${shouldWrite ? 'write' : 'dry-run'}`);
  if (skipped.length > 0) {
    console.log(JSON.stringify({ skipped }, null, 2));
  }
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
