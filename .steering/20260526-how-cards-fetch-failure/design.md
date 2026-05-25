# How Cards Fetch Failure Design

- 原因: Firestore の既存 `how-cards` は `song_id` が `米津玄師-感電` などの legacy slug で保存されているが、Functions serializer が numeric MusicKit ID 以外を全て捨てていた。
- 方針: `POST` / `PATCH` は numeric ID 契約を維持し、`GET` / serializer だけ legacy slug 互換を持たせる。
- iOS は曲別取得で slug も送る。Home dashboard の `Song.musicKitID` には numeric ID だけを入れ、legacy slug を MusicKit 再生 ID と誤認しないようにする。
- 検証: Firestore REST API で legacy slug データを確認し、Functions deploy 後に `/how-cards` と `/how-cards?song_id=...` が実データを返すことを確認する。
