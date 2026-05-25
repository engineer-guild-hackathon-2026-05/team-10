const SEED_VERSION = '20260525-how-card-feed-v1';

const songCatalog = [
  artist('ここのっか', ['ここのっか', '一筋', '春は溶けて', 'ふたつ']),
  artist('Aimer', ['Midnight Bloom', '蝶々結び', 'ref:rain']),
  artist('King Gnu', ['白日', 'Teenager Forever', '三文小説']),
  artist('YOASOBI', ['夜に駆ける', '群青', 'アイドル', '怪物']),
  artist('米津玄師', ['感電', 'Lemon', 'Pale Blue', '打上花火']),
  artist('Vaundy', ['Soda Pop', '怪獣の花唄', 'napori']),
  artist('Mrs. GREEN APPLE', ['ライラック', '青と夏', '点描の唄', 'StaRt']),
  artist('King & Prince', ['ツキヨミ', 'Magic Touch', 'ichiban']),
  artist('Official髭男dism', ['Pretender', 'I LOVE...', 'Subtitle', 'Cry Baby']),
].flat();

const feedComments = [
  { userID: 'seed_mio_x', comment: '今日ずっと聴いてる。サビが沁みる。', goods: 142 },
  { userID: 'seed_ren_fm', comment: '雨の朝にぴったり🎵', goods: 88 },
  { userID: 'seed_sora_24', comment: 'ドライブBGM決定。', goods: 231 },
  { userID: 'seed_hana_music', comment: 'このメロディ反則すぎる…', goods: 67 },
  { userID: 'seed_kai_waves', comment: 'この曲で泣いた笑', goods: 304 },
  { userID: 'seed_yuki_beats', comment: '何回でも聴ける。', goods: 189 },
];

const communityComments = [
  card('米津玄師', '感電', 'seed_demo_me', '歌詞の映像喚起力に完全に引き込まれた。コンビニの灯りの描写が刺さりすぎた。', 341),
  card('米津玄師', '感電', 'seed_demo_me', 'イントロから頭が動いてしまう。ビートとベースラインの絡みが最高。', 287),
  card('米津玄師', '感電', 'seed_haru_m', 'この歌詞で泣いた', 132),
  card('YOASOBI', '夜に駆ける', 'seed_nocturnalvibes', '深夜ドライブに最高', 116),
  card('米津玄師', '感電', 'seed_groove_seeker', 'ビートに乗れて最高', 98),
  card('米津玄師', 'Lemon', 'seed_lyric_nerd', '歌詞の世界に入り込む', 86),
  card('米津玄師', '感電', 'seed_afterglow99', '余韻が抜けない', 74),
  card('米津玄師', '打上花火', 'seed_hype_machine', 'テンションが爆上がり', 69),
  card('米津玄師', '感電', 'seed_still_water_v', '心が落ち着く', 52),
  card('RADWIMPS', '愛にできることはまだあるかい', 'seed_kokoro_kizamu', 'この一節が全部', 47),
];

function buildSeedHowCards() {
  const feedCards = songCatalog.flatMap(song =>
    feedComments.map((template, index) => ({
      ...template,
      song_id: song.songID,
      artist_id: song.artistID,
      song_start: 12 + index * 18,
      song_end: 20 + index * 18,
    }))
  );

  return [...feedCards, ...communityComments].map(item => ({
    id: `seed_${hash(`${item.song_id}:${item.userID}:${item.comment}`)}`,
    comment: item.comment,
    song_start: item.song_start,
    song_end: item.song_end,
    song_id: item.song_id,
    artist_id: item.artist_id,
    user_id: item.userID,
    goods: item.goods,
  }));
}

async function seedHowCardsIfNeeded(db, FieldValue, { force = false } = {}) {
  const metadataRef = db.collection('app-metadata').doc(SEED_VERSION);
  const metadata = await metadataRef.get();
  const cards = buildSeedHowCards();

  if (metadata.exists && !force) {
    return { seeded: false, count: cards.length, version: SEED_VERSION };
  }

  const now = FieldValue.serverTimestamp();
  const writes = cards.map(seedCard => ({
    ref: db.collection('how-cards').doc(seedCard.id),
    data: {
      comment: seedCard.comment,
      song_start: seedCard.song_start,
      song_end: seedCard.song_end,
      song_id: seedCard.song_id,
      artist_id: seedCard.artist_id,
      user_id: seedCard.user_id,
      goods: seedCard.goods,
      created_at: now,
      updated_at: now,
    },
  }));

  for (let index = 0; index < writes.length; index += 450) {
    const batch = db.batch();
    writes.slice(index, index + 450).forEach(write => {
      batch.set(write.ref, write.data, { merge: true });
    });

    if (index + 450 >= writes.length) {
      batch.set(metadataRef, {
        version: SEED_VERSION,
        card_count: cards.length,
        seeded_at: now,
      });
    }

    await batch.commit();
  }

  return { seeded: true, count: cards.length, version: SEED_VERSION };
}

function artist(artistName, songTitles) {
  const artistID = stableIdentifier(artistName);
  return songTitles.map(title => ({
    title,
    artistName,
    artistID,
    songID: `${artistID}-${stableIdentifier(title)}`,
  }));
}

function card(artistName, title, userID, comment, goods) {
  const artistID = stableIdentifier(artistName);
  return {
    userID,
    comment,
    goods,
    song_start: 24,
    song_end: 34,
    song_id: `${artistID}-${stableIdentifier(title)}`,
    artist_id: artistID,
  };
}

function stableIdentifier(value) {
  const normalized = value
    .toLowerCase()
    .replace(/\s+/g, '-')
    .replace(/[^a-z0-9\-ぁ-んァ-ン一-龥ー&.]/g, '');
  return normalized || 'unknown';
}

function hash(value) {
  let hashValue = 2166136261;
  for (let index = 0; index < value.length; index += 1) {
    hashValue ^= value.charCodeAt(index);
    hashValue = Math.imul(hashValue, 16777619);
  }
  return (hashValue >>> 0).toString(16);
}

module.exports = {
  SEED_VERSION,
  buildSeedHowCards,
  seedHowCardsIfNeeded,
};
