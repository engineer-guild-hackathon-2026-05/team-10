# How Cards Fetch Failure Requirements

- `GET /how-cards?song_id=...` へ MusicKit / iTunes numeric ID 以外を送らない。
- Artist catalog の fallback slug しかない曲でも、Howカード画面が取得失敗表示にならない。
- Functions の書き込み契約（`song_id` は numeric ID のみ）は維持する。
- 既存の `project.pbxproj` 未コミット変更には触れない。
