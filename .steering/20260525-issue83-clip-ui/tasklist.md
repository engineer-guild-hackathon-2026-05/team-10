# Issue #83 clip selection UI

- [x] Issue #83 の要件と対象ファイルを確認する
- [x] `origin/main` 起点の作業ブランチを作成する
- [x] 上部再生バーから切り抜き範囲マーカーを削除する
- [x] 範囲選択を中央波形へ一本化し、左右ハンドルを明確にする
- [x] sheet 版と NowPlaying inline 版の UI / 操作を共通化する
- [x] ビルドと差分チェックを実行する
- [x] AI_USAGE_LOG.md に作業ログを追記する
- [x] コミット・push・PR 作成を行う

## 振り返り

- 上部バーは再生位置のみを示す共通コンポーネントへ整理し、切り抜き範囲の操作は中央波形だけにした。
- sheet版とinline版は同じ `ClipRangeSelectionView` を使うため、表示・操作の差分が出にくくなった。
- 波形に左右ハンドルを追加し、操作説明文に頼らず範囲の端を認識できる見た目にした。
- PR: https://github.com/engineer-guild-hackathon-2026-05/team-10/pull/93
