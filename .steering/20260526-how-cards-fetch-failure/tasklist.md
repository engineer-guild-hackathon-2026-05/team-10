# How Cards Fetch Failure Tasklist

- [x] 修正用ブランチ `fix/how-cards-fetch-failure` を作成する
- [x] Howカード取得失敗の表示元と API 経路を確認する
- [x] Functions `/how-cards` を実際に呼んで slug `song_id` が 400 になることを確認する
- [x] iOS から invalid `song_id` を送らないよう修正する
- [x] Firestore 実データを確認し、既存 Howカードが legacy slug `song_id` で保存されていることを確認する
- [x] Functions の GET / serializer を legacy slug 互換に修正する
- [x] iOS の曲別取得で legacy slug を送れるように戻す
- [x] Home dashboard の `musicKitID` に legacy slug を入れないよう修正する
- [x] Functions をデプロイし、実 API で `/how-cards` と legacy slug 検索が非空になることを確認する
- [x] AI_USAGE_LOG.md を更新する
- [x] `git diff --check` と iOS build で検証する
- [x] commit / push する
