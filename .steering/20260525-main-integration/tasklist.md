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

## フェーズ4: 再度 main 取り込みと playback 修正

- [x] `git pull origin main` を実行し、main 更新を取り込む
- [x] main の playback UI を優先して merge conflict を解消する
- [x] NowPlaying の戻る操作を左上 chevron に変更する
- [x] NowPlaying の歌詞表示をスクロール可能にする
- [x] 検証後に `AI_USAGE_LOG.md` を更新する
- [x] 変更をコミットして push する

## フェーズ5: NowPlaying 歌詞 UI 簡素化

- [x] `Section 1・イントロ` の表示を削除する
- [x] 歌詞カードの全文表示ボタンを削除する
- [x] `[Intro]` / `[Verse 1]` などの section 見出しを表示しないようにする
- [x] 歌詞を常時フラットに全行表示し、文字色を `.white` に統一する
- [x] NowPlaying 右上の接続状態 UI を削除する
- [x] 検証後に `AI_USAGE_LOG.md` を更新する
- [x] 変更をコミットして push する

## フェーズ6: Howカード実データ接続

- [x] Functions の `how-cards` レスポンスを `goods` に統一する
- [x] 既存 UI モックコメントを `how-cards` seed データとして定義する
- [x] ~~Functions 初回取得時に seed データを Firestore へ投入する~~（フェーズ8で iOS から `POST /how-cards` を逐次呼ぶ方式へ変更）
- [x] iOS の Howカード取得先を Functions の本番 URL に向ける
- [x] MusicFeed の mock fallback を削除し、Functions 取得結果だけで表示する
- [x] Community を `GET /how-cards` の取得結果から構成する
- [x] ローカル seed スクリプトを実行し、ADC 不在で手元からの投入はできないことを確認する
- [x] Node 構文チェックと iOS ビルドを実行する
- [x] 検証後に `AI_USAGE_LOG.md` を更新する
- [x] 変更をコミットして push する

## フェーズ7: Howカード seed warmup 修正

- [x] ~~`ContentView` の main 起動時に `GET /how-cards?limit=1` を叩く~~（フェーズ8で iOS 逐次 POST 方式へ変更）
- [x] ~~Community 導線に依存せず Functions の seed 判定が走るようにする~~（フェーズ8で iOS 逐次 POST 方式へ変更）
- [x] iOS ビルドを実行する
- [x] `AI_USAGE_LOG.md` を更新する
- [x] 変更をコミットして push する

## フェーズ8: iOS 逐次 POST seed 方式への変更

- [x] Functions 側の GET 自動 seed と seed スクリプトを削除する
- [x] iOS 側に初期 Howカード seed データを移す
- [x] main 起動時に既存 Howカードを取得して重複を判定する
- [x] 不足している Howカードだけ `POST /how-cards` を逐次呼び出して追加する
- [x] Node 構文チェックと iOS ビルドを実行する
- [x] `AI_USAGE_LOG.md` を更新する
- [x] 変更をコミットして push する

## フェーズ9: GoogleService-Info.plist の追跡解除

- [x] `GoogleService-Info.plist` が git 追跡対象になっているパスを確認する
- [x] ローカルファイルを残したまま `git rm --cached` で追跡から外す
- [x] `.gitignore` に `GoogleService-Info.plist` の ignore ルールがあることを確認する
- [x] GitHub 履歴上の混入範囲を確認する
- [x] `AI_USAGE_LOG.md` を更新する
- [x] 変更をコミットして push する

## フェーズ10: 歌詞取得と users 表示修正

- [x] `NowPlayingView` の固定歌詞配列を削除し、Musixmatch 取得結果を表示する
- [x] Musixmatch Provider で LRC subtitle を優先取得し、静的歌詞へ fallback する
- [x] ~~`users` の一括取得 / seed endpoint を Functions に追加する~~（フェーズ11で削除し、iOS から Firestore SDK で直接 seed する方式へ変更）
- [x] iOS 起動時に既存 Howカードに対応する users seed を呼び出す
- [x] Community / MusicFeed で `users.display_name` を表示する
- [x] Node 構文チェックと iOS ビルドを実行する
- [x] `AI_USAGE_LOG.md` を更新する
- [x] 変更をコミットして push する

## フェーズ11: users seed の iOS 直接 Firestore 書き込み化

- [x] Functions の `GET /users` と `POST /users/seed` 追加を削除する
- [x] iOS の `UserSeedService` を Firestore SDK での逐次 `users/{uid}` 書き込みに変更する
- [x] Community / MusicFeed の users 取得 fallback を Functions ではなく Firestore SDK に変更する
- [x] Node 構文チェックと iOS ビルドを実行する
- [x] `AI_USAGE_LOG.md` を更新する
- [x] 変更をコミットして push する
