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

async function main() {
  const shouldWrite = process.argv.includes('--write');
  if (!admin.apps.length) {
    admin.initializeApp();
  }

  const snapshot = await admin.firestore().collection('how-cards').get();
  const batch = admin.firestore().batch();
  const skipped = [];
  let queued = 0;

  snapshot.docs.forEach(doc => {
    const data = doc.data();
    const currentSongId = data.song_id;

    if (typeof currentSongId !== 'string' || isMusicKitSongId(currentSongId)) {
      return;
    }

    const migration = LEGACY_SONG_ID_MIGRATIONS[currentSongId];
    if (!migration) {
      skipped.push({ id: doc.id, song_id: currentSongId });
      return;
    }

    batch.update(doc.ref, {
      song_id: migration.song_id,
      song_slug: typeof data.song_slug === 'string' ? data.song_slug : migration.song_slug,
      song_title: typeof data.song_title === 'string' ? data.song_title : migration.song_title,
      artist_name: typeof data.artist_name === 'string' ? data.artist_name : migration.artist_name,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    queued += 1;
  });

  console.log(`how-cards scanned=${snapshot.size} queued=${queued} skipped=${skipped.length} mode=${shouldWrite ? 'write' : 'dry-run'}`);
  if (skipped.length > 0) {
    console.log(JSON.stringify({ skipped }, null, 2));
  }

  if (!shouldWrite || queued === 0) {
    return;
  }

  await batch.commit();
  console.log('migration committed');
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
