# AI 活用ログ — Team {{TEAM_NUMBER}}

審査項目「AI 活用度」の根拠資料。Day1〜Day3 を通して、AI ツールをどう使ったかを記録する。
**最低 1 日 3 件以上**の記入を目安に。

## 記入ルール

- 開発の節目ごとに追記する（5 分単位で書くより、機能/論点単位で書く）
- プロンプトは「実際に投げた文」を残す（要約は審査時に減点要因になりうる）
- 出力評価は **採用 / 一部採用 / 不採用** の 3 値で正直に
- 「採用しなかった理由」も書くと AI 活用の判断力アピールになる

---

## Day 1（2026-05-24）

### #001 アイデア発散

- **時刻**：HH:MM
- **ツール**：（ChatGPT / Claude / Cursor / GitHub Copilot / etc.）
- **目的**：
- **プロンプト**：
  ```
  （実際のプロンプト）
  ```
- **出力サマリ**：
- **評価**：採用 / 一部採用 / 不採用
- **採用 / 不採用の理由**：

### #002 （次のログ）

- **時刻**：23:12
- **ツール**：Codex
- **目的**：歌詞表示画面の可読性改善、SyncBeat の再生 UI 参照、SwiftUI Preview/ビルド確認
- **プロンプト**：
  ```
  歌詞の表示画面などが今うまく表示されないようになっている。previewとかをうまく使って、xcode mcpとかと掛け合わせて歌詞がしっかり表示されることをあなたの方でもチェックしながら、UIをおしゃれに組み直して欲しい。今は文字が見えにくかったり散々です。全然良くない。
  ```
- **出力サマリ**：
  - SyncBeat の `AIPlaylistGenerateView` / `MusicPlayerView` を参照し、円形アートワーク + 波形リングの再生画面に再構成
  - 歌詞はアートワーク下のスクロールパネルに移動し、現在行へ自動スクロールする構造に変更
  - プレイヤー操作は `ZStack` の手前に浮かぶ固定レイヤーへ分離
  - SwiftUI Preview 用の同期歌詞サンプルデータを追加し、xcodebuild でビルド確認
- **評価**：採用
- **採用 / 不採用の理由**：スクショで問題になっていた背景上の文字の読みにくさを、アートワーク・歌詞・プレイヤーのレイヤー分離で解消できたため。

### #003 コード品質・秘匿情報・モック依存チェック

- **時刻**：23:37
- **ツール**：Codex
- **目的**：不要コード、実行時モック依存、秘匿ファイル管理、backend / iOS の品質改善
- **プロンプト**：
  ```
  いったん、全体のコードを読んでリファクタリングしてみて欲しい。不要なコードがあったり、モックだけで動かないコードがあったり、ENVやgoogleservice-infoがgitに上がっていたりしないかどうか。品質の高いコードになっているかどうかをチェックしてください
  ```
- **出力サマリ**：
  - git 管理下と `.gitignore` を確認し、tracked だった Xcode 個人状態ファイルを削除対象に整理
  - HowChat の backend URL / mock 判定を ENV 経由にし、Release で暗黙 mock にならないよう修正
  - backend に API key 未設定 guard、リクエスト正規化、history 正規化、tool 出力検証を追加
  - 未参照 SwiftUI コンポーネントと実行時の暗黙モック反応を整理し、Preview 用サンプルと実データ経路を分離
  - `node --check backend/index.js` と iOS Simulator 向け xcodebuild で検証
- **評価**：採用
- **採用 / 不採用の理由**：秘匿ファイル、動かない UI、暗黙 mock、backend の入力境界をまとめて潰し、ビルドまで通せたため。

### #004 未選択Home UIの削ぎ落としとSimulator確認

- **時刻**：23:48
- **ツール**：Codex
- **目的**：曲未選択時の冗長なプレイヤー/歌詞UIを削除し、Simulatorで崩れを確認
- **プロンプト**：
  ```
  曲を選んでいない時のUIがひどい。真ん中の音楽SFSymbolsやHowTuneの文字は必要ないし、Lyricsをわざわざ四角で囲んだりLYRICSというテキストを表示する必要なんてない。曲が選ばれていない時のUIについても、スケルトンを追加するとかにして欲しい。曲を選んでくださいとあるけど、曲を選ぶUIが一番最初に出てくるのが普通だよね。あと全体が赤いrectangleの背景になってしまっているのはどうして？全体的に無駄が多すぎる。無駄を削って。波形についても曲が流れていない間は表示しなくていいよね。ほんとうにSyncBeatのコードをしっかりと読んだんでしょうか？
  あと「リスニング開始」のUIって何？ここも競合してしまっていると思う。役割をしっかり考えて統一して欲しい。
  ```
- **出力サマリ**：
  - 曲未選択時は検索導線とスケルトンのみ表示する構成に変更
  - 未選択時のアートワーク、HowTune文字、歌詞枠、LYRICSラベル、波形、ミニプレイヤー、リスニング開始ボタンを削除
  - 曲が未選択なら初回表示時に曲選択シートを自動表示
  - 波形は再生中のみ表示し、停止中は細い進捗バーに変更
  - iOS Simulator にインストールしてHome未選択画面をスクリーンショット確認
- **評価**：採用
- **採用 / 不採用の理由**：未選択状態と再生状態の役割を分離し、ユーザー指摘の冗長要素を実画面で削除確認できたため。

---

## Day 2（2026-05-25）

### #005 再生画面のSyncBeat寄せ再構成とSimulator確認

- **時刻**：00:15
- **ツール**：Codex
- **目的**：再生中Home UIの作り直し、SyncBeatの波形/プレイヤー構成の再読、歌詞表示の可読性改善、Simulator確認
- **プロンプト**：
  ```
  UIがひどい。歌詞がはみ出ているし、波形がしっかりと動いていない。プレイヤーが消えているから再生中止ができない。[AtsushiHosaka/SyncBeat](https://github.com/AtsushiHosaka/SyncBeat)もう一度sync beatのコードを見て、波形や背景をなるべくsync beatに寄せて欲しい。その上で歌詞をその下にスクロールできる形で入れると言うか。背景のアートワークは削除していい。歌詞のところはもっと大きく。スクロールしたら波形表示なども一緒に上に行くようにしていいと思う。曲名を表示するところがないのはひどい。tabviewのところまでスクロールができないようになっているのもひどい。一から再生画面を作り直すくらいの感じでもいいので、しっかりと作って欲しい。
  ```
- **出力サマリ**：
  - SyncBeat の `AIPlaylistGenerateView` / `MusicPlayerView` / `CircularWaveformView` / `CircularWaveformShape` を再読し、Home の再生画面を縦スクロール主体に再構成
  - 背景アートワークを削除し、黒基調の背景、円形波形、円盤アートワーク、曲名/アーティスト、進捗、再生/一時停止、歌詞カードを同じスクロール文脈に整理
  - `SyncBeatCircularWaveformView` を追加し、再生中に30fpsでなめらかに動く円形波形を実装
  - MusicKit の再生/一時停止状態を即時に `isPlaying` へ反映し、波形と一時停止ボタンの状態が遅れないよう修正
  - Debug限定のプレビュー起動フラグを追加し、Simulatorで選曲済み再生画面を直接表示して確認
  - `xcodebuild`、`git diff --check`、1秒差スクリーンショット比較で検証
- **評価**：採用
- **採用 / 不採用の理由**：曲名・プレイヤー・歌詞が初期表示で読める構成になり、歌詞の横はみ出しと停止不能状態を解消し、Simulatorで最終表示と波形差分を確認できたため。

### #006 再生画面の仕上げ・How/AI導線復旧

- **時刻**：00:47
- **ツール**：Codex
- **目的**：波形safe area、進捗UI、Howカード/コメント導線、Groove表示、AI深掘り導線の回帰確認
- **プロンプト**：
  ```
  結構良くなった。波形が隠れてしまっているからそこだけ空白を増やして。safeareaで隠れちゃってるのが勿体無いのかな。あと曲のタイトルの背景色は透明にすればいいんじゃないかな？
  また、プレイヤーUIの部分、ただのSliderだと勿体無いから色とかつけよう。

  Howカードの部分がしょぼすぎる。コメントとかつけられる、ってはずだったのにそうなっていない。ここをタップすればいいんだ、とかもわからないようになっている。改善して。

  また、今の曲の音量などから、今の曲のグルーヴ感についても感じ取れるようにしてくれるといいのかなと思う。それに伴って、この曲のこんな感じが好き、みたいなのが話せるから。

  あとAIをつかって対話を深ぼる、みたいな機能があったはずなんだけどデグレしている？過去のコミットログを見てみて。
  ```
- **出力サマリ**：
  - 過去コミット `15aa754` / `48a1103` / `7b5fdad` を確認し、AI対話とHowカード作成導線がHome歌詞タップから外れていたことを特定
  - Homeの歌詞行を `How / コメント / AIと深掘り` が見えるタップ可能カードにし、タップで `HowChatView` を開く導線を復旧
  - Howカード作成画面とReactionDisplay画面にコメント入力欄を追加
  - 波形の上余白とサイズを調整し、波形描画をフレームサイズ基準にしてsafe area付近のクリップを解消
  - プレイヤーの進捗をグラデーションと拍目盛り付きのメーターに変更し、曲名背景は透明化
  - 音量と再生位置から軽量なGroove表示を追加し、歌詞の操作導線が初期表示で見えるようコンパクト化
  - `xcodebuild` とSimulator実機操作で、再生画面表示と歌詞タップからAI対話シートが開くことを確認
- **評価**：採用
- **採用 / 不採用の理由**：ユーザー指摘のsafe area、Slider感、How導線の弱さ、AI対話回帰をまとめて修正し、Simulator上で導線まで確認できたため。

### #007 PR #41 の main 追従とコンフリクト解消

- **時刻**：12:49
- **ツール**：Codex
- **目的**：PR #41（AirPods reaction detection）の GitHub コンフリクトを main 優先で解消し、ビルド確認まで行う
- **プロンプト**：
  ```
  https://github.com/engineer-guild-hackathon-2026-05/team-10/pull/41 このPRのコンフリクトを直してpushまでやってください。たぶんmainを優先していいです
  ```
- **出力サマリ**：
  - PR #41 の head が `feat/issue-14-reaction-detection`、base が `main` であることを確認
  - `origin/main` を取り込み、`SensorStatusCard.swift` の modify/delete 競合を main 側の削除として解消
  - main 側の再生同期UIとPR側のリアクション検出コードの接続差分を調整
  - `MusicKitPlaybackService` の `PlaybackPositionProviding` 準拠、`ReactionDetectionViewModel` の `Combine` import、`HowTag` の `Hashable` 明示、Home の旧タイムライン遷移残骸を整理
  - `xcodebuild -quiet -project Othello/Othello.xcodeproj -scheme Othello -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/OthelloDerivedData build` でビルド通過を確認
- **評価**：採用
- **採用 / 不採用の理由**：GitHub上の競合原因を解消し、main優先のUI構成を保ったままPRブランチがビルド可能になったため。

### #008 PR #57 の docs コンフリクト解消

- **時刻**：12:57
- **ツール**：Codex
- **目的**：PR #57（feature/tensorflow）の docs コンフリクトを、現状のiOSアプリ・ai-recognition構成に合わせて自然に統合する
- **プロンプト**：
  ```
  今度は https://github.com/engineer-guild-hackathon-2026-05/team-10/pull/57 のPRでコンフリクトしている。docsだから、内容が自然に（現状の内容を）表すように編集して欲しい
  ```
- **出力サマリ**：
  - PR #57 の head が `feature/tensorflow`、base が `main` であることを確認
  - `origin/main` を取り込み、`docs/architecture.md`、`docs/functional-design.md`、`docs/slides/howtune.md` の競合を解消
  - `ai-recognition` は groove / chill / neutral の3状態収集・学習、iOSアプリは6軸 `ReactionScore` 表示という二層構造として説明を整理
  - スライド内に残っていたWeb前提の技術構成を、SwiftUI / MusicKit / Core Motion / Firebase Functions / Firestore / Core ML 構成へ更新
  - `docs/product-requirements.md` も3状態候補から6軸可視化する表現に合わせた
  - `rg` による競合マーカー確認、`git diff --check`、`git diff --cached --check` で検証
- **評価**：採用
- **採用 / 不採用の理由**：3状態と6軸のどちらか一方を消すのではなく、現在の実装と学習データ収集の関係として自然に読める内容に統合できたため。

### #009 FirestoreコメントAPIとAuthユーザー保存

- **時刻**：13:30
- **ツール**：Codex
- **目的**：Howカードコメントの Firestore 直書きモデル/API、FirebaseAuth ユーザー作成後の users 保存を実装する
- **プロンプト**：
  ```text
  firestoreとコメントをつなぐところの機能開発をして欲しい。firestoreのデータ構造は次のようになっています。how-cardsコレクションの中にドキュメントがあり、comment, song_id, artist_id, user_id, goods(integer)←いいねの数 が保存されている感じ。ドキュメントをまずはこの内容で更新し、それに合わせてコードも書いていってください。Viewと繋ぎこむところはまだで良くて、Firebase APIみたいなものが作れていて、structがあり、encode decodeできるようになっていればいいかなと思います。また、FirebaseAuthでユーザー作成して、作ったユーザーをusersコレクションに保存する機能もまだだから、そこについても開発しておいて欲しい
  ```
- **出力サマリ**：
  - `docs/data-model.md` を `how-cards` の `comment/song_id/artist_id/user_id/goods` 構造と `users/{uid}` 構造に更新
  - `HowCardComment` / `FirestoreUser` の Firestore Codable model を追加
  - `FirebaseAPI` を追加し、Howカード作成・更新・取得・goods加算・ユーザー保存/取得を実装
  - `AuthViewModel.signUp` で FirebaseAuth 作成後に `users/{uid}` を保存し、保存失敗時は signOut するよう変更
  - iOSターゲットに `FirebaseFirestore` を追加し、Firestore Rules も認証済みユーザー向けの最小権限へ更新
  - `xcodebuild` と `git diff --check` で検証
- **評価**：採用
- **採用 / 不採用の理由**：View接続前のデータ層として必要な Codable model と API 境界を作り、Auth 作成と Firestore ユーザー保存を同じフローに統合できたため。

### #010 PR #60 レビュー対応

- **時刻**：13:44
- **ツール**：Codex
- **目的**：CodeRabbit の PR レビュー指摘を反映し、再ビルドして push する
- **プロンプト**：
  ```text
  https://github.com/engineer-guild-hackathon-2026-05/team-10/pull/60　レビューが返ってきているから直してpushしなおして
  ```
- **出力サマリ**：
  - `AI_USAGE_LOG.md` と `docs/data-model.md` の fenced code block に言語指定を追加
  - Firestore Rules の `users` create/update を分離し、`created_at` 不変性と `updated_at == request.time` を検証
  - `users` 保存を `Date()` ではなく `FieldValue.serverTimestamp()` で書くよう修正
  - Auth 作成後の Firestore 保存失敗時に、signOut 失敗も `FirebaseAPIError.signOutRollbackFailed` として通知
  - `xcodebuild` と `git diff --check` で検証
- **評価**：採用
- **採用 / 不採用の理由**：レビュー指摘4件をすべて反映し、Firestore Rules と iOS 書き込み実装の整合性を保ったままビルド通過できたため。

### #011 PR #60 Firestoreアクセスのバックエンド経由化

- **時刻**：13:55
- **ツール**：Codex
- **目的**：iOS から Firestore を直接呼ばず、既存 backend/functions API 経由で Howカードコメントとユーザー保存を扱う構成へ変更する
- **プロンプト**：
  ```text
  ごめん、現在でているPRをみてみると、バックエンドサーバーを通してFirebaseの色々をいじるような構成になってますよね。それを使えるような繋ぎ込みを先にやった方がいいかもしれない。よくPRの変更を見ながら、直接Firestoreを呼び出さないように変更してもらってもいいですか？
  ```
- **出力サマリ**：
  - `backend/` と `functions/` に `POST/GET/PATCH /how-cards`、`POST /how-cards/:id/goods`、`GET/PUT /users/me` を追加
  - iOS の `FirebaseAPI` を Firestore SDK 直呼びから Firebase ID トークン付き URLSession API クライアントへ変更
  - `HowCardComment` / `UserProfile` を backend response/request 用 Codable model に変更し、`FirebaseFirestore` 依存を削除
  - Firestore Rules を deny-all に戻し、Firestore 書き込みは Admin SDK を持つバックエンドに集約
  - data model / backend docs / steering docs をバックエンド経由構成に更新
- **評価**：採用
- **採用 / 不採用の理由**：既存の backend/functions 構成に合わせ、クライアントがFirestoreに直接触らない境界へ整理できたため。

### #012 Howカードコメントの範囲フィールド追加

- **時刻**：14:09
- **ツール**：Codex
- **目的**：Howカードコメント型を `song_start` / `song_end` を含む新スキーマへ更新する
- **プロンプト**：
  ```text
  how_cardについて、今後バックエンド（functions）の中で方が変わることになった：
  comment, song_start, song_end(rangeが別れた）, song_id, artist_id, user_id, goods
  そうなるようにiosのドキュメント・実装を変更して欲しい
  ```
- **出力サマリ**：
  - `HowCardComment` と `FirebaseAPI` の Howカードコメント payload に `songStart` / `songEnd` を追加
  - `backend/` と `functions/` の Howカードコメント API で `song_start` / `song_end` を必須入力として検証・保存・返却するよう更新
  - `docs/data-model.md`、`docs/backend.md`、`backend/README.md`、steering docs を新スキーマへ更新
- **評価**：採用
- **採用 / 不採用の理由**：iOS の Codable model / API payload と backend/functions の入出力スキーマを同じ `song_start` / `song_end` 前提に揃えられたため。

### #013 PR #63 レビュー対応と main conflict 解消

- **時刻**：14:35
- **ツール**：Codex
- **目的**：PR #63 のレビューコメント反映、`origin/main` 取り込みによる functions 競合解消、main 側 backend(functions) 機能との整合性確認
- **プロンプト**：
  ```text
  レビューコメントがついているのと、main conflictがあるから、そこをなおして。現状のmainのbackend(functions)の機能と競合していないかどうかについてもチェックして欲しい
  ```
- **出力サマリ**：
  - `origin/main` を取り込み、`functions/README.md` / `functions/repositories/firestore.js` / `functions/routes/how-cards.js` の競合を解消
  - main 側の `onUserSignup` と冪等な `/how-cards/:id/like` を残しつつ、Howカードコメントの Firestore スキーマを `comment/song_start/song_end/song_id/artist_id/user_id/goods` に統一
  - `users/me` の email は Firebase ID トークンを正とし、body の email が異なる場合は 400 を返すよう修正
  - iOS の API クライアントを `/how-cards/:id/like` と 401/403 ハンドリングに合わせ、直接 Firestore 依存が戻っていないことを確認
  - Markdown fence の言語指定、review nit の route コメント削除、deprecated backend 側の同等修正も反映
- **評価**：採用
- **採用 / 不採用の理由**：main 側 functions の Auth トリガーと idempotent like を保持したまま、PR の新スキーマ・レビュー指摘・競合解消を同時に成立させられたため。

### #014 PR #63 再レビュー対応

- **時刻**：14:47
- **ツール**：Codex
- **目的**：CodeRabbit の追加レビュー指摘を反映し、再検証して push する
- **プロンプト**：
  ```text
  再度レビューがつけられた。修正してpushして
  ```
- **出力サマリ**：
  - functions の `GET /how-cards?song_id=...` を `created_at` 降順にし、対応する Firestore composite index を追加
  - `users.created_at` は有効な snake_case Timestamp のみ保持し、legacy `createdAt` を流用しないよう修正
  - `FirebaseAPI.swift` から `FirebaseAPIError` / Envelope / Payload 型を分割し、Swift の 1ファイル1型ルールへ合わせた
  - deprecated backend 側も同じ timestamp/order 方針へ合わせた
- **評価**：採用
- **採用 / 不採用の理由**：レビューの実指摘を最小差分で解消しつつ、Firestore index とローカル backend の挙動も揃えられたため。

### #015 発表スライドの仕上げ（スライド4・9・11・12）

- **時刻**：01:30
- **ツール**：Claude Code
- **目的**：python-pptx でスライドを更新。スライド4タイトル変更、スライド9を実装に合わせてpill更新、スライド11を技術ロゴ画像ベースに、スライド12をガラスカードスタイルに統一
- **プロンプト**：
  ```
  9に関して 実装に合わせてスライドを調整して
  スライド11を画像ベースにして
  ビジネスモデルのスライドをさっきさくせいしたけいしきの綺麗さに揃えて欲しい
  ```
- **出力サマリ**：
  - スライド4タイトルを「聴き方は、伝わらない。」に変更
  - スライド9のpillラベルをHomeView実装（volume × 0.42 + sinusoid）に合わせて🎵🔥❄️🎧💫✨の日本語に更新
  - スライド11はdevicon CDNからSVGを取得しcairosvgでPNG変換、Swift/Firebase/Musixmatch/Create MLのロゴ画像に差し替え
  - スライド12（ビジネスモデル）をガラスカード + カラードットスタイルに統一
- **評価**：採用
- **採用 / 不採用の理由**：実装事実（音量+サインカーブ）とスライドの記述を一致させ、技術スライドも実ロゴで視覚的にわかりやすくなったため。

### #016 HowChat深掘りAI改善（実モーション6軸スコア接続）

- **時刻**：02:30
- **ツール**：Claude Code
- **目的**：AirPodsモーションの実スコアをHowChatに接続し、定型文応答を解消。dominant軸ベースの動的選択肢・2ターン制・バックエンドコンテキスト改善
- **プロンプト**：
  ```
  次はHOW投稿を手伝うAIを作成していきます。動きに対して深掘りするもので、3回は多いと思うのでどこかのドキュメントに書いてあると思うけどgrill-meした方針に則って実装して欲しいです。現状とずれそうだったらうまく方針を聞いたりして。最新のメインブランチからgh issue -> /steering -> 実装の順で
  少し待って 今６つの軸は疑似コードで残っている可能性が高いです 動きを収集していると思うのでそれをローカルで処理してそこからAIがインサイトをするという方向でいけないですか？最適化がおおすぎ？
  MLを作らないとダメ？ 激しく動いていた部分に関してはかんたんに抜き出せそう
  ```
- **出力サマリ**：
  - `MotionReactionScoreEstimator`（ルールベース算術、ML不要）で `AirPodsMotionSample` → 6軸スコア生成を確認
  - `ReactionEvent` に `score: ReactionScore` フィールド追加、`ReactionScore` に `asDictionary` 拡張追加
  - `HomeView` に `AirPodsMotionViewModel` を接続し、歌詞タップ時に実スコアで `reactionEvent(for:)` を生成
  - `ChatPayload` に `scores/dominantAxis` 追加、`mockResponse` を groove/hype・hit/immersion・chill/afterglow の動的分岐に変更
  - `HowChatViewModel` のターン数を 3→2 に削減
  - `backend/index.js` の `systemPrompt` / `buildContextMessage` / `normalizeChatRequest` を dominant 軸対応に改善
  - xcodebuild（`-sdk iphonesimulator`）でビルド成功を確認
- **評価**：採用
- **採用 / 不採用の理由**：MLモデル不要のルールベースで実スコアをHowChatに接続でき、定型文応答を dominant 軸ベースの動的選択肢に差し替えられたため。PR #73 で完了。

---

## Day 3（2026-05-26）

### #00X

---

## 全体振り返り

- **AI が一番効いた場面**：
- **AI に頼らなかった場面とその理由**：
- **次回 Hackathon で改善したい AI 活用**：
