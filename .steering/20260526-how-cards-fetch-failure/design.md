# How Cards Fetch Failure Design

- 原因: `Song.firestoreSongID` は `musicKitID` がない場合に title/artist 由来 slug を返すが、Functions の `GET /how-cards?song_id=...` は numeric ID だけを受け付ける。
- 方針: iOS の API boundary で `songID` を正規化し、numeric ID 以外の曲別取得はネットワークへ送らず空配列にする。
- 影響範囲: `FirebaseAPI.fetchHowCards(songID:limit:)` のみ。Community / Home の全件取得は従来どおり実行する。
- 検証: 実 Functions に slug query を送ると 400 になることを確認し、修正後は iOS build を通す。
