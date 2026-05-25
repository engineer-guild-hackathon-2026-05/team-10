# How Cards Fetch Failure Requirements

- `GET /how-cards?song_id=...` は既存 Firestore データの legacy slug `song_id` も取得できる。
- Artist catalog の fallback slug しかない曲でも、曲別 Howカード画面が取得失敗表示にならない。
- 全件 / おすすめコメント取得で legacy slug の Howカードを serializer が捨てない。
- Functions の新規書き込み契約（`song_id` は numeric ID のみ）は維持する。
- 既存の `project.pbxproj` 未コミット変更には触れない。
