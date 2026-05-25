# 設計書

## アーキテクチャ概要

既存の SwiftUI + MVVM 構成を維持し、UI 表示に関する変更を `HomeView` と `LyricRow` に閉じる。

```
PlaybackViewModel / LyricsViewModel
        ↓
HomeView
  ├─ ScrollView
  │   └─ Now Playing card
  │       ├─ Circular artwork stage
  │       └─ Lyrics scroll panel
  └─ ZStack overlay
      └─ Floating player deck
```

## コンポーネント設計

### 1. HomeView

**責務**:
- 再生中トラック、歌詞状態、現在再生位置に基づく画面表示。
- アートワーク、同期歌詞、固定プレイヤーのレイヤー分離。

**実装の要点**:
- 歌詞はアートワークに直接置かず、アートワーク下のスクロールパネルに表示する。
- 現在行は `ScrollViewReader` で中央へ寄せ、背景と文字色で強調する。
- プレイヤーは `ZStack` の手前に固定し、歌詞スクロールとは独立して操作できるようにする。
- Preview 用にモック状態を注入できる initializer を追加する。

### 2. Floating Player Deck

**責務**:
- 曲情報、再生/停止、前後移動、再生進捗の表示。
- 歌詞スクロール中でも常に操作できる再生 UI。

**実装の要点**:
- `ZStack(alignment: .bottom)` に配置し、ScrollView の下余白でコンテンツが隠れないようにする。
- SyncBeat の `MusicPlayerView` に近い、アートワークサムネイル + 操作ボタン + 波形進捗の構成にする。

## データフロー

### 歌詞表示
```
1. ユーザーが曲を選択する。
2. LyricsViewModel が同期歌詞を取得する。
3. HomeView が現在再生位置から現在行を算出する。
4. 歌詞スクロールパネルが現在行へ自動スクロールする。
5. 浮遊プレイヤーはスクロール位置に関係なく表示される。
```

## エラーハンドリング戦略

- 既存の `LyricsLoadingState` を利用し、未選択/読み込み中/取得不可/空データを UI 状態として表現する。
- 取得不可時は歌詞パネル内に短いメッセージを表示し、画面全体の構造は崩さない。

## テスト戦略

### Preview
- 長い英語 + 日本語歌詞を含む同期歌詞の Preview を追加する。
- 歌詞なし/未選択状態は既存 Preview で確認する。

### ビルド
- Xcode プロジェクトを iOS Simulator 向けにビルドする。

## 依存ライブラリ

新規依存は追加しない。

## ディレクトリ構造

```
Othello/Othello/Views/Home/HomeView.swift
Othello/Othello/Views/Home/LyricRow.swift
```

## 実装の順序

1. Preview 注入用の initializer とサンプルデータを追加する。
2. SyncBeat の再生 UI 構造を参照する。
3. 円形アートワークと歌詞スクロールパネルを実装する。
4. 浮遊プレイヤーを `ZStack` の固定レイヤーとして実装する。
5. ビルドで確認する。

## セキュリティ考慮事項

- API キーや外部通信まわりは変更しない。

## パフォーマンス考慮事項

- 表示対象は既存どおり現在位置周辺の行に限定し、全歌詞の再描画負荷を増やさない。

## 将来の拡張性

- 反応スコアや心拍トレンドを行内バッジとして追加できる余白を残す。
