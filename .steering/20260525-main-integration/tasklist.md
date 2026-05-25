# main統合タスクリスト

## フェーズ1: 状態確認

- [x] `pull origin main` で最新 main を取り込む
- [x] 最新 main 取り込み後のビルド状態を確認する
- [x] main UI と既存の Firebase/MusicKit/Auth/AirPods 実装の接続点を確認する

## フェーズ2: iOS 統合

- [x] main UI の構成を維持しつつ、丸いアートワークと円形波形表示を NowPlaying/mini player に統合する
- [x] MusicFeed の曲タップを MusicKit 再生に接続する
- [x] Firebase Functions 経由で Howカードを取得・いいね・投稿できるようにする
- [x] Auth 済みユーザー前提で Firebase API 呼び出しが使える状態を維持する
- [x] AirPods 頭部モーションを MusicKit 再生位置と同期して開始できるようにする

## フェーズ3: 検証・記録

- [x] Node の構文チェックを実行する
- [x] iOS ビルドを実行する
- [x] `AI_USAGE_LOG.md` を更新する
- [x] 変更をコミットして push する
