# Home Dashboard Renewal Design

## Data Flow

Home 専用の view model が既存の `FirebaseAPI.fetchHowCards(songID:limit:)` を `songID` なしで呼び、既存 endpoint の `GET /how-cards` から最新コメントを取得する。新しい Firebase Functions endpoint は追加しない。

取得した `HowCardComment` は Home 表示用の `HomeDashboardComment` に変換する。表示用モデルでは、コメント、曲 ID、アーティスト ID、いいね数、MusicKit から解決できた曲名・アーティスト名・ジャケット URL を保持する。

ジャケット画像は以下の順で決める。

1. MusicKit catalog lookup で `song_id` から取得した artwork URL
2. 現在再生中トラックの artwork URL
3. 既存の gradient fallback

## UI Structure

現在ログイン後の main screen は `ContentView` から `ForYouView` を表示しているため、この画面を Home dashboard として扱う。既存のアーティストカード導線は上部の横スクロールに整理し、下部におすすめコメント dashboard を追加する。

アーティストカードは画像を全面に敷き、下部に黒の overlay を薄く入れてテキスト可読性を確保する。既存の For You 画面でも同じ背景描画を使えるよう、`Artist` / `Song` に artwork URL を追加する。

おすすめコメントは MusicFeed の投稿カードと近い密度で表示する。Home では一覧性を優先し、コメント本文、アーティスト名、曲名、再生区間、いいね数を表示する。

## Navigation

`ForYouView` の `NavigationStack` に artist selection と comment selection を追加する。コメントタップ時に selection をセットし、`MusicFeedView(artist:highlightedComment:)` へ遷移する。

`MusicFeedView` は任意の `highlightedComment` を受け取り、feed の先頭に強調表示する。これにより Home から遷移したコメントが見失われない。

## Risk

既存 how-card API は `likes` を返すが、iOS model は `goods` を期待している。デコードを `goods` / `likes` の両対応にし、既存 API と Firestore 設計の差を吸収する。
