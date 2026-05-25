# Design

- `MusicKitPlaybackService` が `MusicSubscription.current.canPlayCatalogContent` を確認し、再生可能性を `AppleMusicAccessStatus` として公開する。
- `PlaybackViewModel` が access status とメッセージを View に渡す。
- `ContentView` と `HomeView` に Apple Music 未契約時の明示バナー / empty state を表示する。
- `ContentView` / `OnboardingView` は Welcome と AirPods motion の2画面構成にする。
- `OnboardingViewModel` から HealthKit 依存と心拍許可処理を削除する。
