# 用語集

> 2026-05-25 時点の実装に追従する。

## How

**定義**: 何を聴いているかではなく、曲のどの部分をどのように楽しんでいるか。

**例**: 「ここの声が掠れている感じが好き」「このベースラインが普通に着地しない感じが好き」。

## Howカードコメント

**定義**: 曲中の一定区間に紐づくユーザーコメント。Firestore の `how-cards` に保存される。

**主要フィールド**: `comment` / `song_start` / `song_end` / `song_id` / `artist_id` / `user_id` / `goods`

## HowTag

**定義**: 反応状態を表す3状態タグ。

| tag | 表示 | 意味 |
|---|---|---|
| `groove` | のっている | リズムや身体の動きが強い状態 |
| `chill` | ちるい | 静かに浸る、落ち着いた状態 |
| `neutral` | neutral | 明確な groove/chill ではない状態 |

## ReactionScore

**定義**: `groove / chill / neutral` の 0〜1 スコア。AirPods 頭部モーション特徴量と Core ML 補助推論から算出する。

## ReactionEvent

**定義**: 曲中の反応区間。画面表示や HowChat の入力に使う。現行 Functions には永続化しない。

**主要フィールド**: `startTime` / `endTime` / `intensity` / `tags` / `lyricLine`

`heartRateTrend` は legacy 表示互換として型に残っているが、現行実装では実測心拍に基づかない。

## AirPods 頭部モーション

**定義**: AirPods の加速度・回転速度・姿勢を `CMHeadphoneMotionManager` で取得したもの。

**本プロジェクトでの用途**: 曲中時刻に同期し、反応検出とビジュアライザーに使う。

## CMHeadphoneMotionManager

**定義**: AirPods 等の頭部モーションを取得する iOS Core Motion API。

## MusicKit

**定義**: Apple Music の楽曲検索・再生・再生位置取得を提供する iOS framework。

**本プロジェクトでの用途**: 曲検索、再生、再生位置の取得。

## Musixmatch

**定義**: 歌詞取得 API。

**本プロジェクトでの用途**:

1. `matcher.track.get` で曲を照合
2. `track.subtitle.get` で LRC 形式の時間同期歌詞を取得
3. 失敗時は `track.lyrics.get` で静的歌詞へ fallback

## SynchronizedLyrics

**定義**: 歌詞 provider から返る歌詞モデル。`isTimeSynced` が true の場合は再生位置に応じて行ハイライトできる。

## Firebase Functions

**定義**: 本番 API のデプロイ先。`functions/` に実装がある。

**主な endpoint**: `/health`, `/how-cards`, `/users/me`

## Firebase Auth

**定義**: ログインと Firebase ID token 発行に使う認証基盤。

**本プロジェクトでの用途**: Functions API への request に `Authorization: Bearer <token>` を付与する。

## Firestore

**定義**: Firebase の document database。

**本プロジェクトでの用途**: `users` と `how-cards` を保存する。Howカードコメントは Functions の Admin SDK 経由で扱う。`users/{uid}` はログイン中ユーザー自身に限って iOS から Firestore rules 経由で read/write する。

## goods / likes

**定義**: Howカードコメントのいいね数。Firestore の canonical field は `goods`。API response では互換のため `likes` も同じ値で返す。

## legacy backend

**定義**: `backend/` に残る旧 Express 実装。

**注意**: `/sessions` や Claude 連携の参照実装が残るが、本番 deploy には反映されない。新規 API は `functions/` に追加する。

## HealthKit

**定義**: iOS のヘルスデータ framework。

**本プロジェクトでの扱い**: 現行 MVP から削除済み。心拍・HRV・HealthKit 権限は要求しない。
