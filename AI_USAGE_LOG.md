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
  ```text
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
  ```text
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
  ```text
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
  ```text
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
  ```text
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
  ```text
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
  ```text
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
  ```text
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

### #010 main の Home UI デグレ疑い調査

- **時刻**：13:08
- **ツール**：Codex
- **目的**：main ブランチで playback-ui の Home 画面機能が失われたように見える原因を Git ログから調査する
- **プロンプト**：
  ```text
  ちゃんとみてみたら、mainブランチでHome画面の機能、歌詞の表示やアートワークの周りの波線などが全部デグレしてしまっています。playback-uiブランチでやってたはずなんだけど、さっきのマージの時に失われてしまったんだと思う。再度さっきのものを取り戻したいから、gitのログをみてほしい
  ```
- **出力サマリ**：
  - `feat/playback-lyrics-ui` は `87f1d6e` の PR #53 で main にマージ済みであることを確認
  - その後の PR #41 / #54 / #57 は Home の再生UI・歌詞・波形周辺を消す差分ではないことを確認
  - ローカル `main` が古い `9399cfa` のままで、`origin/main` にある Home UI 追加前の状態だったことを特定
  - `Package.resolved` の untracked 衝突を、リモートと同一内容であることを確認してから除去し、`main` を `542bb6f` まで fast-forward
  - 現在の `main` に `displayLyrics`、`SyncBeatCircularWaveformView`、`artworkDisk`、`HowChatView` が存在することを確認
- **評価**：採用
- **採用 / 不採用の理由**：デグレの原因がマージ消失ではなくローカル main の未更新であることをログと差分で切り分け、最新 main へ復旧できたため。

### #011 ハッカソン質疑応答ページ作成

- **時刻**：13:34
- **ツール**：Codex / Notion MCP / Web search
- **目的**：Team Notion に、ハッカソン発表で聞かれそうな質問例と返答例を市場・競合・マネタイズ調査込みで作成する
- **プロンプト**：
  ```text
  https://www.notion.so/Team-36a72123fc438008a80ff226574fce0a?source=copy_link ここに質疑応答ページを作って、このハッカソンの質疑応答で聞かれそうな質問例と返答例を作って欲しい。既存市場とか競合サービスとの差別化、マネタイズなど、いろんなものを調べながらやってほしい
  ```
- **出力サマリ**：
  - Notion の Team ページ配下に「質疑応答想定集（ハッカソン発表）」を作成
  - リポジトリ内の PRD / 機能設計 / 技術仕様 / スライド案と、Notion の既存アイデア・仕様・勝ち筋ページを確認
  - IFPI、Spotify、Apple Music、Last.fm、stats.fm、Airbuds、Bandcamp、Apple Developer などを調査
  - 競合比較、30秒回答テンプレ、想定 Q&A 40問、厳しめ質問への返し、参考ソースを整理
- **評価**：採用
- **採用 / 不採用の理由**：HowTune の「What ではなく How」「AI は断定しない」「身体反応ヒートマップ」という差別化を、質疑でそのまま使える回答形式に落とし込めたため。

### #012 Musixmatch同期歌詞とMusicKit音源分離の調査

- **時刻**：13:42
- **ツール**：Codex / Web search / Musixmatch API疎通確認
- **目的**：Musixmatch Basicプランで時間同期歌詞を取得できるか、MusicKit音源に対してベース/ドラムなどのステム分離を行えるかを規約面込みで調査する
- **プロンプト**：
  ```text
  相談したい。現在musixmatch APIをつかっていて、Basicプランで契約してるんだけど、リアルタイムで（時間に対応する形で）lyricを取得できる？時間が分かりさえすればいい。いまはstaticになってしまっている。
  あと、MusicKitで取得した音源に対して、ベースの音だけ、ドラムの音だけを切り抜く、みたいなことってできるの？もしできるのならすごい嬉しいんだけど。有料APIでもよく、MusicKitと組み合わせられるか、規約に反さないか、という観点からよく調べてみて欲しい
  ```
- **出力サマリ**：
  - Musixmatch公式ドキュメントで `track.subtitle.get` / `matcher.subtitle.get` / `track.richsync.get` の役割を確認
  - 現在のAPIキーで同期歌詞系エンドポイントを叩き、HTTP 200内のMusixmatchステータスが `403 Forbidden` になることを確認
  - `MusixmatchLyricsProvider` が現状 `track.lyrics.get` の静的歌詞のみを使い、行番号を擬似時刻にしていることを確認
  - MusicKitは再生・メタデータ用で、Apple規約上 MusicKit Content のダウンロード/アップロード/改変/同期が制限されることを確認
  - AudioShake / Moises / LALAL.AI / Spleeter などのステム分離手段は、Apple Musicストリームではなく、権利処理済み音源ファイルが必要という整理を行った
- **評価**：採用
- **採用 / 不採用の理由**：同期歌詞はプラン権限の問題、音源分離はMusicKit音源の直接処理不可という切り分けができ、実装可能な代替案まで整理できたため。

### #013 PR #60 レビュー対応

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

### #014 PR #60 Firestoreアクセスのバックエンド経由化

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

### #015 Howカードコメントの範囲フィールド追加

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

### #016 PR #63 レビュー対応と main conflict 解消

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

### #017 PR #63 再レビュー対応

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

### #018 AirPods連動ビジュアライザーと3状態分類整理

- **時刻**：14:03
- **ツール**：Codex / Context7 / Web search / xcodebuild
- **目的**：Home の波形表現を AirPods モーションと再生状態に連動させ、6軸分類仕様を3状態分類へ整理する
- **プロンプト**：
  ```text
  feature/airpods-interaction ブランチに分けて、次の機能を作って：
  git pull origin mainしてある前提。SyncBeat...とかで波形とかが表示されていると思う（この命名からSyncBeatと言うのを消して欲しい）のだけど、これをAirPodsの動作と掛け合わせるようにして欲しい。AirPodsから動きを取得するようにして、その動きが激しければ波形を大きく、小さければ小さくして欲しい。また、現在の波形の動かし方って音源に対応していないけど、がんばってフーリエ変換して有機的に動くようにして欲しい。AirPodsの動きがあったら、パーティクルがきらきらと散るような感じにしてもいいね。もし可能ならmetalを使ってこれらの実装をすると良いのかなと思った。どうでしょうか？MusicKitの内容を調べて実装可能かどうかをちゃんと調べた上でやってみてほしい。

  ごめん、mainが更新されたからgit pull origin main, merge mainしたのちで実装を続けて欲しい

  さっきってwaveの色がグラデーションになってたけど、AirPods経由で取得された動きによって色を変える、というようにできますか?
  また、仕様として6段階の分類は消えていて（これについては対応するドキュメントを更新して欲しいです。ai-recognitionも見ながら進めてください）、6段階の分類ではなく、のっている、ちるい、neutralの3種類に分けるように。この情報についてテキストで表示する必要はありません。
  ```
- **出力サマリ**：
  - `feature/airpods-interaction` を作成し、`origin/main` の最新更新を取り込み。`AI_USAGE_LOG.md` の競合は既存ログと作業ログを両方残して解消
  - Apple 公式ドキュメントで MusicKit / Core Motion / Accelerate の実装可能範囲を確認。MusicKit から Apple Music ストリームのPCMやスペクトラムは取得できないため、`playbackTime` とトラック情報を種にした vDSP FFT ベースの疑似スペクトラムとして実装
  - `SyncBeatCircularWaveformView` を削除し、`AirPodsReactiveWaveformView` と `AudioMotionSpectrumAnalyzer` を追加
  - `CMHeadphoneMotionManager` のサンプルから movement intensity を算出し、波形の振幅・パーティクル・色を AirPods の動きに連動
  - 6軸分類を `groove` / `chill` / `neutral` の3状態に整理し、画面上では分類テキストを表示せず、波形色で反映
  - `docs/` と `ai-recognition/` の6軸分類前提を3状態分類へ更新
  - `xcodebuild` と `git diff --check` で検証
- **評価**：採用
- **採用 / 不採用の理由**：MusicKit の制約を調査で明確にしたうえで、実機AirPodsモーションと再生時刻ベースのFFT表現を組み合わせ、仕様変更後の3状態分類へコード・ドキュメント・AI認識メタデータをそろえられたため。

### #019 AirPodsモーション取得デバッグログ追加

- **時刻**：14:12
- **ツール**：Codex / xcodebuild
- **目的**：AirPods の動きが実際に取得されているかを Xcode コンソールで確認できるようにする
- **プロンプト**：
  ```text
  AirPodsの動きが全然反映されていない。まずはAirPodsの動きを取得されているかどうか、printしてみてほしい
  ```
- **出力サマリ**：
  - Home 側に `[AirPodsMotion][Home]` ログを追加し、再生状態・トラック有無・手動モード・取得開始/停止条件を確認できるようにした
  - `AirPodsMotionManager` に `[AirPodsMotion]` ログを追加し、接続状態更新、デバイスモーション可否、開始/停止、エラー、サンプル取得を確認できるようにした
  - サンプルログは 0.5 秒間隔に間引き、`intensity`、加速度、回転速度、再生位置を出力するようにした
  - `#if DEBUG` で囲み、Debug ビルドだけで出力されるようにした
  - `xcodebuild` でビルド通過を確認
- **評価**：採用
- **採用 / 不採用の理由**：反映されない原因が「取得開始に進んでいない」のか「Core Motion サンプルが届いていない」のかを、実機ログで切り分けられる状態にできたため。

### #020 AirPods取得開始条件の修正

- **時刻**：14:15
- **ツール**：Codex / xcodebuild
- **目的**：手動モード時にも AirPods モーション取得を開始できるようにする
- **プロンプト**：
  ```text
  そもそもairpodsのログが出てきていない
  ```
- **出力サマリ**：
  - 実機ログから `[AirPodsMotion][Home] ... manualMode=true` により取得開始が止まっていることを特定
  - `HomeView.syncAirPodsMotionCapture()` の開始条件から `!viewModel.useManualMode` を外し、再生中かつ曲があれば AirPods モーション取得を開始するよう修正
  - 手動モードはリアルタイム反応画面のフォールバック表示には使うが、AirPods の頭部モーション取得自体はブロックしない整理にした
  - `xcodebuild` でビルド通過を確認
- **評価**：採用
- **採用 / 不採用の理由**：AirPods マネージャーのログが出なかった直接原因を取り除き、次回実機確認で Core Motion の可否とサンプル取得まで切り分けられるようになったため。

### #021 AirPods一時切断耐性とneutral波形の音量反映

- **時刻**：14:19
- **ツール**：Codex / xcodebuild
- **目的**：AirPods モーション取得が一時的な disconnect 通知で止まる問題を修正し、neutral 状態でも音源の大きさで波形が動くようにする
- **プロンプト**：
  ```text
  [AirPodsMotion] device motion updates starting
  [AirPodsMotion] headphone motion connected
  [AirPodsMotion] headphone motion disconnected
  [AirPodsMotion] device motion updates stopped
  ...
  あと、neutralの時に波形が動かなさすぎる。音源のデカさでちゃんと動くようにして欲しい
  ```
- **出力サマリ**：
  - `AirPodsMotionStatus.isRecording` を `.starting` も含む判定にし、取得開始直後の二重 start を抑制
  - `AirPodsMotionManager` に `isCaptureRequested` を追加し、重複 start を無視するようにした
  - `headphoneMotionManagerDidDisconnect` で即 `stop()` しないようにし、一時的な disconnect 通知でサンプル取得を止めないよう修正
  - connect 時に capture requested なら device motion updates を再確認/再開するようにした
  - サンプルが2秒届かない場合に `active` / `deviceMotionAvailable` / `connectionStatusActive` をログ出力する watchdog を追加
  - neutral 状態でも `audioLevel` が波形厚み・グロー・FFT入力に強く効くように調整
  - `xcodebuild` でビルド通過を確認
- **評価**：採用
- **採用 / 不採用の理由**：ログから見えた一時 disconnect による停止を潰し、AirPods が静止していても音源由来の動きが視覚的に出るようにできたため。

### #022 CoreML判定のHome波形接続と色補間

- **時刻**：14:24
- **ツール**：Codex / xcodebuild
- **目的**：AirPods 波形の「のっている」判定を閾値ベースから CoreML 推論ベースに変更し、色変化を滑らかにする
- **プロンプト**：
  ```text
  色の変化がガクガクなのはおかしいから、もっと滑らかに変化するようにして欲しい。あと、乗ってる の判定がキツすぎるかも。もっと簡単にそこにタッセルといいなぁと思いました

  いまってCoreMLをつかって乗ってるかどうかの判定している？

  いや、CoreMLをつかって乗ってるかどうかの判定してほしいんだけど…
  ```
- **出力サマリ**：
  - Home の AirPods サンプルを `ReactionDetectionViewModel` に流し、`OthelloActivityClassifierService` の CoreML 推論結果から `ReactionScore` を更新するようにした
  - Home の `waveformReactionState` を raw motion 閾値ではなく CoreML 推論込みの `ReactionScore` から決めるように変更
  - リアルタイム反応画面も `MotionReactionScoreEstimator` 直結ではなく `ReactionDetectionViewModel` 経由に変更し、CoreML 推論パスへそろえた
  - `AirPodsReactiveWaveformView` に色専用のローパス値を追加し、neutral / chill / groove のパレットを `smoothstep` で連続補間するようにした
  - 「のっている」判定は `groove` スコアが少し優位なら入りやすい条件に調整
  - `xcodebuild` でビルド通過を確認
- **評価**：採用
- **採用 / 不採用の理由**：ユーザーの意図どおり、AirPods モーションの状態判定を CoreML 推論結果に接続し、見た目の色変化も離散的な切替ではなく滑らかにできたため。

### #023 Metal描画化とAirPods/CoreML処理負荷の削減

- **時刻**：14:33
- **ツール**：Codex / xcodebuild
- **目的**：波形描画と AirPods 連動処理の CPU 負荷を下げ、実機でのカクつきと Energy Impact を抑える
- **プロンプト**：
  ```text
  重たすぎて全然動いていない。metalを使う必要があるのかもしれない
  ```
- **出力サマリ**：
  - SwiftUI `Canvas` ベースだった AirPods 波形を `MTKView` + Metal シェーダー描画へ置き換え
  - 波形リングとパーティクルを GPU 側の三角形プリミティブで描画する構成にし、フレームレートを再生中 30fps / 停止中 10fps に制御
  - FFT 解析の bin 数を削減し、vDSP FFT setup をキャッシュしてフレームごとの生成/破棄を避けるようにした
  - AirPods の取得頻度は落とさず、CoreML の window 評価だけを 0.25 秒間隔にスロットリング
  - `xcodebuild` でビルド通過を確認
- **評価**：採用
- **採用 / 不採用の理由**：AirPods モーションの反応性を残したまま、描画負荷の中心だった SwiftUI path 再生成を Metal に移し、実機での負荷低減が期待できるため。

### #024 Metal setVertexBytes 4KB制限クラッシュ修正

- **時刻**：14:38
- **ツール**：Codex / xcodebuild
- **目的**：AirPods 反応時のパーティクル描画で `setVertexBytes` の 4KB 制限に当たり SIGABRT する問題を修正する
- **プロンプト**：
  ```text
  Thread 1: signal SIGABRT
  length(4224) must be <= 4096.
  encoder.setVertexBytes(baseAddress, length: rawBuffer.count, index: 0)
  ```
- **出力サマリ**：
  - Metal Debug Layer のログから、パーティクル頂点データが `setVertexBytes` の上限 4096 bytes を超えていることを特定
  - パーティクル描画を `setVertexBytes` ではなく shared `MTLBuffer` へコピーして `setVertexBuffer` で渡す方式に変更
  - GPU が前フレームの buffer を読んでいる可能性を避けるため、3本の vertex buffer をローテーションする実装にした
  - `xcodebuild` でビルド通過を確認
- **評価**：採用
- **採用 / 不採用の理由**：クラッシュログの直接原因である Metal API のサイズ制限を回避し、パーティクル数が増えても描画を継続できるため。

### #025 波形の有機化とneutral復帰判定の調整

- **時刻**：14:46
- **ツール**：Codex / xcodebuild
- **目的**：波形の山が固定されて見える問題とカクつき、neutral 判定に戻りにくい問題を修正する
- **プロンプト**：
  ```text
  fftで分析、みたいになっているんだったらちゃんと波形が変わると思うんだけど、波形のでかいところが変わらない。
  あと、neutral判定がされなくなった。これはMLModelの問題なのかな？
  あと、波がカクカクしているから滑らかにつなぐようにして欲しいな。
  ちゃんとfftできるんだろうか？できないなら適当に有機的で滑らかな曲線を重ねるとかでもいいと思います
  ```
- **出力サマリ**：
  - MusicKit から生音源 PCM は取得できないため、実音源 FFT ではなく再生時間・曲ID・音量相当値から作る有機的な疑似スペクトラムとして整理
  - FFT bin を 128 に増やし、ピーク位置が時間で流れる lobe とスペクトルテクスチャを合成するようにした
  - Metal 波形の頂点数増加に備え、波形リングも shared `MTLBuffer` 経由に変更
  - 波形リングを 96〜256 セグメントで補間描画し、頂点間の角張りを軽減
  - neutral 判定はセンサーの絶対値ではなくウィンドウ内の変化量を重視するよう特徴量とスコアリングを調整
  - Create ML Data Source では `neutral: 0` の警告が残っているため、モデル再生成が必要な可能性を確認
  - `xcodebuild` でビルド通過を確認
- **評価**：採用
- **採用 / 不採用の理由**：MusicKit の制約を踏まえて見た目を滑らかにしつつ、モデル不整合があってもアプリ側の特徴量 fallback で neutral に戻りやすくできたため。

### #026 波形スムージングと細粒度Metalパーティクル再調整

- **時刻**：14:51
- **ツール**：Codex / xcodebuild
- **目的**：波形のピクつきを抑え、見た目を少し大きくし、AirPods 反応時のパーティクルを細かく見えるようにする
- **プロンプト**：
  ```text
  かなり良い感じ。波形がピクピクしてしまっているから、ランダム性をより滑らかにできるといい。もう少し波形がデカくてもいいかも。
  パーティクル機能は無くなった？metalで実装し直して欲しい。前のパーティクルより細かくていい
  ```
- **出力サマリ**：
  - 波形のターゲット振幅をフレーム間で直接差し替えず、低域通過的に追従させる smoothing を追加
  - 疑似スペクトラムのピーク移動速度とスペクトルテクスチャを抑え、空間方向の smoothing pass を増やした
  - Home の波形表示サイズと Metal 側の波形厚みを少し増やした
  - Metal パーティクルを小粒の diamond spark に変更し、発火閾値を下げて最大数を増やした
  - パーティクルも shared `MTLBuffer` 経由の Metal 描画のまま維持
  - `xcodebuild` でビルド通過を確認
- **評価**：採用
- **採用 / 不採用の理由**：描画負荷を増やしすぎずに、波形の時間的な滑らかさと AirPods 反応時の細かい視覚フィードバックを強められたため。

### #027 AirPodsモーション時の波形拡大とパーティクル発火強化

- **時刻**：14:54
- **ツール**：Codex / xcodebuild
- **目的**：AirPods モーションが来た時にパーティクルを出やすくし、波形の拡大反応を強める
- **プロンプト**：
  ```text
  やっぱパーティクルがでてこない。もうちょい出安くしてほしい
  air podsからモーションが来た時に、より波形が大きくなるようにして欲しい。結構大きくてもいい
  ```
- **出力サマリ**：
  - パーティクル発火閾値を大きく下げ、AirPods の小さな motion でも粒が出るようにした
  - モーション由来の particle budget 増加量と最大同時パーティクル数を増やした
  - パーティクルの alpha / size / life / velocity を調整し、画面上で見えやすくした
  - 波形 view の表示サイズをさらに拡大し、Metal 側の motion 厚み係数を強めた
  - motion smoothing の追従速度も上げ、AirPods の動きが波形サイズへ早めに反映されるようにした
  - `xcodebuild` でビルド通過を確認
- **評価**：採用
- **採用 / 不採用の理由**：AirPods モーションに対する視覚反応が弱かった箇所を、発火条件・描画サイズ・波形拡大係数の3点から強められたため。

### #028 パーティクル可視化の再確認と色遷移速度調整

- **時刻**：14:58
- **ツール**：Codex / xcodebuild
- **目的**：パーティクルが見えない原因を実装から見直し、AirPods モーション時の波形反応と色遷移を調整する
- **プロンプト**：
  ```text
  まじで全くパーティクルが出てきてないんだけど。黒いパーティクルでも出してるんですか？ちゃんと実装を見返してみて、パーティクルが出るようになっているのか教えて欲しい。また、もうちょいAirPodsの動きに反応して波形を大きくして欲しい。あと色のトランジションをもうちょいゆっくり行うようにして欲しい
  ```
- **出力サマリ**：
  - パーティクル実装は残っており黒ではないが、小さい motion 値をそのまま使うため粒が薄く見えにくい状態だったことを確認
  - motion 値を非線形に boost して、小さな AirPods 動作でもパーティクルと波形拡大に効くよう変更
  - パーティクルを neutral 時は白寄り、groove/chill 時は色付きにし、alpha / size / velocity / life をさらに強化
  - 最大パーティクル数増加に合わせて Metal shared vertex buffer を 512KB に拡張
  - AirPods motion による波形厚み係数をさらに上げ、内側半径を少し締めて外側に大きく伸びるようにした
  - 色トランジションのローパス係数を下げ、状態変化時の色変化をゆっくりにした
  - `xcodebuild` でビルド通過を確認
- **評価**：採用
- **採用 / 不採用の理由**：実装上の発火経路と描画経路を確認したうえで、見えない原因だった motion の弱さ・粒の薄さ・buffer 余裕をまとめて改善できたため。

### #029 AirPods波形サイズの中間調整

- **時刻**：15:01
- **ツール**：Codex / xcodebuild
- **目的**：AirPods モーション時の波形拡大が強すぎたため、前回と前々回の中間程度に戻す
- **プロンプト**：
  ```text
  ごめんデカすぎる。今とさっきのとの中間くらいにして欲しい
  ```
- **出力サマリ**：
  - 波形用 motion boost を `pow(rawMotion, 0.62) * 1.38` に下げた
  - パーティクル用 motion boost は維持し、粒の出やすさを保つようにした
  - 波形の内側半径と motion 厚み係数を中間寄りに調整
  - `xcodebuild` でビルド通過を確認
- **評価**：採用
- **採用 / 不採用の理由**：パーティクルの見えやすさを保ちながら、AirPods motion で広がりすぎた波形だけを抑えられたため。

### #030 AirPods連動機能PR作成

- **時刻**：15:05
- **ツール**：Codex / git / gh
- **目的**：AirPods モーション連動波形機能の変更を PR として提出する
- **プロンプト**：
  ```text
  よさそう。prを立てておいて
  ```
- **出力サマリ**：
  - 機能差分、docs、`ai-recognition`、steering 記録を PR 用に整理
  - 共有対象外の未追跡 Xcode scheme は commit 対象から除外
  - commit / push / PR 作成を実施
- **評価**：採用
- **採用 / 不採用の理由**：実装・検証済みの AirPods interaction 機能をレビュー可能な単位として提出するため。

### #031 PR #67 レビュー対応と main conflict 解消

- **時刻**：15:55
- **ツール**：Codex / GitHub CLI / xcodebuild
- **目的**：PR #67 の CodeRabbit レビュー指摘を反映し、`origin/main` 取り込みによる conflict を解消する
- **プロンプト**：
  ```text
  feature/airpods-interaction がmainとconflictしているから、レビューを読んで直した上でconflict解消して
  ```
- **出力サマリ**：
  - `AI_USAGE_LOG.md` の競合を、main 側ログと AirPods 側ログを両方残す形で解消
  - steering docs の描画方針を SwiftUI Canvas ではなく Metal vertex buffer 構成へ統一
  - `ReactionDetectionViewModel` の時刻基準切替時に throttle/window 状態をリセットするよう修正
  - Home のトラック切替時に AirPods 収集セッションを明示再起動し、manual mode ではセンサー収集を開始しないよう修正
  - `ai-recognition` の3状態 seed data 集計と metadata の dataset limitation note を更新
  - Metal 波形 renderer 周辺を 1ファイル1型へ分割
- **評価**：採用
- **採用 / 不採用の理由**：レビュー指摘を実装・docs・metadata に反映し、main 取り込み後の PR ブランチを再レビュー可能な状態へ戻せたため。

### #032 発表台本ページ作成

- **時刻**：15:27
- **ツール**：Codex / Notion MCP
- **目的**：HowTune の6分発表に向けて、冒頭の語り口を活かした台本を Notion に作成する
- **プロンプト**：
  ```text
  プレゼンを考えている。
  みなさんは、「この曲のギターソロ、かっこいいよね」「この曲のこの歌詞、すごく感動する」といった会話で盛り上がったことありませんか？
  一つの曲の深い理解同士が出会うと、そこに熱狂が生まれます。偏愛が出会い、熱狂が生まれる瞬間です。
  しかし、SNS上で同じような曲の楽しみ方をしている人を見つけるのは、至難の業です。なぜなら、どんな曲が好き、What　を共有することは簡単でも、How、どのように楽しんでいるか、を共有するのは、言葉のみの現在のプラットフォームでは難しいためです。

  ここからどのように続けたらいいだろうか？途中で2分くらいでもが挟まる想定で、マネタイズとかまで行きたい。口調は私のものを真似して欲しい。

  notionに「台本」ページを作って、そこに仮のものを書き込んで欲しい。全体で6分、上のもので1分くらいかかる想定です
  ```
- **出力サマリ**：
  - Team Notion 配下に「台本」ページを作成
  - 6分構成を、導入1分・プロダクト説明1分・デモ2分・技術/AI 1分・マネタイズ/締め1分に分解
  - ユーザーの冒頭文体を保ちつつ、HowTune の身体反応、AIの問いかけ、Howカード、アーティスト向けインサイトまで自然につながる台本を作成
- **評価**：採用
- **採用 / 不採用の理由**：発表の制限時間に合わせて、課題提起からデモ、技術思想、収益化まで一貫して話せるドラフトにできたため。

### #033 発表台本のコンセプト再整理

- **時刻**：15:35
- **ツール**：Codex / Notion MCP / GitHub CLI
- **目的**：HowTune の主軸を「身体反応の言語化」から「曲の一部分の深い聴き方でつながるコミュニティ」へ修正し、台本を一から書き直す
- **プロンプト**：
  ```text
  1. 「深く聴いている人が、同じ/違う聴き方の仲間を見つけて語れる」 が一番。コミュニティのさらなる活性化が行いたいこと。
  2. 単にインタラクション要素。今出ているPRとかをみて欲しいんだけど、airpodsの動きで波形表示が変わるようになっている。体を動かしながら音楽を聴くのって楽しいよね、って言うところから、曲をより楽しむ導入にしたい。
  3. Bです。複数の利き方が見えるとかではない。これも今出ているPRでコミュニティ機能を改善するPRがあります
  4. マネタイズは、コミュニティ機能に出す広告、グッズ・チケット販売、アーティストへのスーパーチャットでこのアプリにアーティストが出てくる　とかにしましょう
  ```
- **出力サマリ**：
  - オープンPR #67（AirPods reactive waveform）と #68（ForYou / MusicFeed / ClipCreation UI）を確認
  - AirPods 波形を「感情推定」ではなく「身体で曲に入るインタラクション」として位置づけ直した
  - Notion の「台本」ページを v2 として全面更新し、深く聴いている人が曲の一部分への聴き方を投稿し、コミュニティ内で同じ/違う聴き方の仲間を見つける構成に変更
- **評価**：採用
- **採用 / 不採用の理由**：ユーザーが定義したプロダクトの主目的に合わせ、発表の中心を自己理解からコミュニティ活性化へ戻せたため。

### #034 Home dashboard の Firebase コメント接続

- **時刻**：18:23
- **ツール**：Codex / xcodebuild
- **目的**：Home 画面をアーティストカードとおすすめコメント dashboard に刷新し、Firebase Functions の実データを表示する
- **プロンプト**：
  ```text
  update/homeとかでブランチ切って、ホーム画面を開発し直したい：

  上の方には今みたいにアーティストのカード出しておくのでいいんだけど、下の方にはおすすめコメントをいくつか出すようなdashboardにしてほしい。コメントのviewは普通のコメントの画面でいい。コメントクリックされたらそのコメントが表示されているアーティストの画面に遷移して、コメントが出てくる感じに。

  実際にfirebase functionを呼び出してfetchした上で、アーティストカードの背景は今の感じじゃなくてアーティストのジャケ写を使えるようにして欲しい。おしゃれなデザインで実装してください
  ```
- **出力サマリ**：
  - `update/home` ブランチで、ログイン後 main screen の `ForYouView` を Home dashboard として再構成
  - 既存の `FirebaseAPI.fetchHowCards` を `song_id` なしでも呼べるようにし、`/how-cards?limit=...` を実際に呼ぶおすすめコメント取得を実装
  - `HomeDashboardViewModel` で Firebase コメントを取得し、MusicKit で `song_id` から曲名・アーティスト名・ジャケット画像を解決する流れを追加
  - アーティストカードをジャケット画像背景に変更し、コメントカードタップで `MusicFeedView` に遷移して対象コメントを先頭に強調表示するようにした
  - Functions が返す `likes` と iOS 側の `goods` のデコード互換を追加
  - steering docs を追加し、xcodebuild と `git diff --check` で検証
- **評価**：採用
- **採用 / 不採用の理由**：既存の main screen 構成に合わせて実データ取得、ジャケット背景、コメントからアーティスト画面への導線をまとめて接続できたため。

### #035 おすすめコメント取得の既存API統合

- **時刻**：18:33
- **ツール**：Codex / xcodebuild
- **目的**：おすすめコメント取得を新規 client helper ではなく、既存 `/how-cards` API と `fetchHowCards` に統合する
- **プロンプト**：
  ```text
  おすすめコメントを取得する、という機能を、既存APIで実装して欲しいなと思っています
  ```
- **出力サマリ**：
  - `fetchRecommendedHowCards` をやめ、既存の `fetchHowCards(songID:limit:)` を `songID` optional に変更
  - `songID` ありなら曲別コメント、なしなら既存 `GET /how-cards` の最新コメント一覧を取得する形に統一
  - Home dashboard のおすすめコメント取得を `api.fetchHowCards(limit: 12)` に差し替え
  - steering docs を既存 API 利用方針に更新
- **評価**：採用
- **採用 / 不採用の理由**：Functions の既存仕様をそのまま使い、iOS 側でもコメント一覧取得 API を1つに統一できたため。

### #036 MusicKit メタデータ解決の slug 対応

- **時刻**：20:32
- **ツール**：Codex / xcodebuild
- **目的**：Firestore の `song_id` が Apple Music catalog ID ではなく slug の場合でも、ジャケット画像と曲情報を取得できるようにする
- **プロンプト**：
  ```text
  [HomeDashboard] MusicKit metadata lookup failed songID=radwimps-愛にできることはまだあるかい error=MusicDataRequest.Error(
    status: 404,
    code: 40400,
    title: "Resource Not Found",
    detailText: "Resource with requested id was not found",
    id: "JB3ZVPRWGNSUETKWDOHBRIDOVQ",
    originalResponse: MusicDataResponse(
      data: 159 bytes,
      urlResponse: <NSHTTPURLResponse: 0x0000000126716380>
    )
  )
  ```
- **出力サマリ**：
  - `song_id` が数値の Apple Music catalog ID に見える場合だけ ID 直引きを試すよう変更
  - `radwimps-愛にできることはまだあるかい` のような slug は `radwimps 愛にできることはまだあるかい` に正規化して MusicKit 検索へフォールバック
  - 検索結果はアーティスト名と曲名の一致度で優先し、見つからない場合のみ既存のテキスト fallback を使うようにした
  - 404 を通常の fallback 対象として扱い、debug log が大量に出ないようにした
- **評価**：採用
- **採用 / 不採用の理由**：Firestore の実データ形式を壊さず、Apple Music ID と内部 slug の両方で dashboard のジャケット補完を試せるようになったため。

### #037 how-cards song_id 契約不整合の issue 化

- **時刻**：20:40
- **ツール**：Codex / GitHub CLI
- **目的**：`song_id` に MusicKit ID 以外の値が入っている backend データ契約問題を GitHub issue として記録する
- **プロンプト**：
  ```text
  これってfunctions側のミスですよね。issueを立てておいてください
  ```
- **出力サマリ**：
  - GitHub issue #78「fix: how-cards の song_id に MusicKit ID 以外の値が入る問題を修正する」を作成
  - `song_id` は MusicKit / Apple Music / iTunes の曲 ID として扱うべきで、slug は `song_slug` / `song_title` など別フィールドに分離すべきと記録
  - Firestore 既存データの migration / seed data 修正、Functions validation、API docs 更新を修正候補として整理
- **評価**：採用
- **採用 / 不採用の理由**：client 側の fallback ではなく backend のデータ契約問題として追跡できる状態にできたため。

### #038 Home dashboard PRレビュー対応

- **時刻**：21:06
- **ツール**：Codex / GitHub CLI
- **目的**：PR #80 のレビューコメントを確認し、Home dashboard の差分リスクを下げる
- **プロンプト**：
  ```text
  #80のPRのコメントを見て直して。
  ```
- **出力サマリ**：
  - コメントカードのハードコードされた返信数表示を削除
  - `HomeDashboardComment` が生成する `Song` / `Artist` の UUID を `song_id` / `artist_id` 由来の安定 ID に変更
  - SwiftUI の identity churn による不要な再描画や選択状態のズレを防ぐようにした
- **評価**：採用
- **採用 / 不採用の理由**：PR レビューで指摘された UI 表示の誤りとモデル identity の不安定さを、小さな差分で解消できたため。

---

## Day 3（2026-05-26）

### #00X

---

## 全体振り返り

- **AI が一番効いた場面**：
- **AI に頼らなかった場面とその理由**：
- **次回 Hackathon で改善したい AI 活用**：
