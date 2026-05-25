# Issue #84 Japanese Demo Copy Requirements

## 背景

デモ画面に英語の曲タイトル、タグ、fallback 文言が混ざっており、日本語中心のプロダクト体験として見せづらい。

## 要件

- For You / MusicFeed / NowPlaying / ClipCreation で見えるデモ曲タイトルとタグを日本語中心にする
- デモ用の再生回数・反応数の表示も英語 placeholder に見えない文言へ寄せる
- MusicKit で取得した正式な英語曲名は実データとしてそのまま扱う
- fallback 文言は `不明なアーティスト` / `不明な曲` など日本語で表示する
- 内部 ID や検索処理の意味は変えず、表示文言のみを変更する

## 非対象

- MusicKit が返す正式タイトルの翻訳
- Firestore schema や Functions API contract の変更
- UI レイアウトの大規模変更
