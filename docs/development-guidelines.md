# 開発ガイドライン (Development Guidelines)

## コーディング規約

### 命名規則

#### 変数・関数（TypeScript）

```typescript
// ✅ 良い例
const sensorFrames = recordMotionData();
function extractFeatureVector(frames: SensorFrame[]): FeatureVector { }
const isRecording = true;
const hasReaction = reactions.length > 0;

// ❌ 悪い例
const data = record();
function calc(arr: any[]): any { }
```

**原則**:
- 変数: camelCase、名詞または名詞句
- 関数: camelCase、動詞で始める（`generate`, `fetch`, `classify`, `detect`）
- 定数: UPPER_SNAKE_CASE（`MAX_SESSION_DURATION_SEC = 600`）
- Boolean: `is`, `has`, `should` で始める

#### クラス・インターフェース

```typescript
// クラス: PascalCase
class MotionAnalyzer { }
class HowDialogOrchestrator { }
class HowCardRepository { }

// インターフェース: PascalCase（I 接頭辞なし）
interface SensorFrame { }
interface ListeningStateScores { }

// 型エイリアス: PascalCase
type HowTag = 'groove' | 'hype' | 'chill' | 'immersion' | 'hit' | 'afterglow';
type SessionStatus = 'recording' | 'analyzing' | 'done';
```

#### React コンポーネント

```tsx
// コンポーネント: PascalCase
export function HowChatDialog({ session }: Props) { }
export function ReactionTimeline({ reactions, duration }: Props) { }

// Props 型: `[コンポーネント名]Props`
interface HowChatDialogProps {
  session: ListeningSession;
  onCardGenerated: (card: HowCard) => void;
}
```

---

### コードフォーマット

- **インデント**: 2スペース（prettier で自動整形）
- **行の長さ**: 最大 100 文字
- **セミコロン**: あり
- **クォート**: シングルクォート（JSX は ダブルクォート）

`.prettierrc`:
```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "printWidth": 100,
  "trailingComma": "es5"
}
```

---

### コメント規約

**WHY が自明でない場合のみ書く**。コードを見れば分かることは書かない。

```typescript
// ✅ 良い例: なぜそうするかを説明
// iOS Safari は HTTPS + ユーザージェスチャー後でないとセンサー許可が取れない
await DeviceMotionEvent.requestPermission();

// ✅ 良い例: 非自明なアルゴリズムの説明
// sliding window で直前2秒との差分をスパイク検出に使う
const prevEnergy = window.slice(-20).reduce((s, f) => s + f.mag, 0) / 20;

// ❌ 悪い例: コードを読めば分かる
// センサーデータを取得する
const frames = await getSensorFrames();
```

---

### 型安全

```typescript
// ✅ 型を明示（any を使わない）
function classifyWindow(features: FeatureVector): ListeningStateScores { }

// ✅ Zod でランタイムバリデーション
const sessionSchema = z.object({
  songTitle: z.string().min(1).max(200),
  sensorData: z.array(sensorFrameSchema).max(36000), // 最大60分
});

// ❌ any は使わない
function classify(data: any): any { }
```

---

### エラーハンドリング

```typescript
// カスタムエラークラス
class SensorPermissionDeniedError extends Error {
  constructor() {
    super('センサーの許可が必要です');
    this.name = 'SensorPermissionDeniedError';
  }
}

// API レイヤーでのエラー処理
app.post('/sessions', async (req, res) => {
  const parsed = sessionSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.flatten() });
  }
  try {
    const session = await motionAnalyzer.analyze(parsed.data);
    res.json(session);
  } catch (error) {
    if (error instanceof LLMUnavailableError) {
      return res.status(503).json({ error: 'AI サービスが一時的に利用できません' });
    }
    console.error('Unexpected error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});
```

**原則**:
- 予期されるエラーは明示的なカスタムクラスで捕捉
- LLM / センサーの障害は必ずフォールバックを用意
- エラーを握りつぶさない（少なくとも `console.error` で記録）

---

### Claude API の使い方

プロジェクトでは Claude API を問いかけ型の対話生成に使う。

```typescript
import Anthropic from '@anthropic-ai/sdk';

const client = new Anthropic(); // ANTHROPIC_API_KEY 環境変数を自動参照

// ストリーミングで返す（TTFB を短くするため必須）
async function* generateQuestion(reaction: ReactionSpan, songTitle: string) {
  const stream = client.messages.stream({
    model: 'claude-sonnet-4-6',
    max_tokens: 200,
    system: SYSTEM_PROMPT, // ユーザー入力とは分離
    messages: [
      {
        role: 'user',
        content: `曲: ${songTitle}\n反応区間: ${reaction.startMs}ms〜${reaction.endMs}ms\nスコア: ${JSON.stringify(reaction.scores)}`,
      },
    ],
  });
  for await (const chunk of stream) {
    if (chunk.type === 'content_block_delta') {
      yield chunk.delta.text;
    }
  }
}
```

**ルール**:
- `system` プロンプトにユーザー入力を混入しない（プロンプトインジェクション対策）
- `model` は `claude-sonnet-4-6`（コスト・性能バランス）
- ストリーミングを使い TTFB 1秒以内を維持

---

## Git 運用ルール

### ブランチ戦略

ハッカソン期間（3日間）は軽量 Git Flow を採用。

```
main
  └─ feat/sensor-recorder       ← 機能開発
  └─ feat/motion-classifier
  └─ feat/how-dialog
  └─ fix/ios-sensor-permission  ← バグ修正
  └─ docs/update-readme         ← ドキュメント
```

**ブランチ名**: `feat/xxx` / `fix/xxx` / `docs/xxx` / `refactor/xxx`

**禁止**: `main` への直接 push（GitHub の branch protection ルールで強制）

---

### コミットメッセージ規約

```
<type>(<scope>): <subject>

Co-Authored-By: Claude <noreply@anthropic.com>
```

| Type | 用途 |
|------|------|
| `feat` | 新機能 |
| `fix` | バグ修正 |
| `docs` | ドキュメント |
| `refactor` | リファクタリング |
| `test` | テスト追加・修正 |
| `chore` | ビルド・設定変更 |

**例**:
```
feat(sensor): DeviceMotionEvent の記録機能を実装

- SensorRecorder クラスを追加
- iOS のセンサー許可フローを実装
- 100ms 間隔でフレームをバッファリング

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

### PR プロセス

**作成前チェック**:
- [ ] 型チェック通過: `pnpm type-check`
- [ ] Lint エラーなし: `pnpm lint`
- [ ] テスト通過: `pnpm test`

**PR テンプレート** (`.github/pull_request_template.md`):
```markdown
## 概要
[変更内容の1行サマリー]

## 変更内容
- [変更点1]
- [変更点2]

## テスト
- [ ] ユニットテスト追加
- [ ] iPhone Safari で動作確認
- [ ] Android Chrome で動作確認

## AI 活用ログへの追記
- [ ] AI_USAGE_LOG.md に追記済み

## 関連 Issue
Closes #[番号]
```

**マージ方針**: Squash merge（コミット履歴をきれいに保つ）

---

## テスト戦略

### テストの種類とカバレッジ目標

| 種別 | 対象 | カバレッジ目標 | ツール |
|------|------|--------------|--------|
| ユニットテスト | `MotionAnalyzer`, `HowDialogOrchestrator`, Repository | 70%（MVP期間） | Vitest |
| 統合テスト | API エンドポイント全体 | 主要ルートのみ | Vitest + Firebase Emulator |
| E2Eテスト | センサー → AI対話 → Howカード | 手動（iOS/Android） | 手動 |

### ユニットテスト例

```typescript
// apps/api/tests/unit/MotionAnalyzer.test.ts
import { describe, it, expect } from 'vitest';
import { MotionAnalyzer } from '../../src/services/MotionAnalyzer';

describe('MotionAnalyzer', () => {
  describe('extractFeatures', () => {
    it('一定リズムで揺れるデータから高い rhythmRegularity を返す', () => {
      const frames = generateRhythmicFrames(/* 2秒分 */);
      const features = MotionAnalyzer.extractFeatures(frames, 2000);
      expect(features.rhythmRegularity).toBeGreaterThan(0.7);
    });

    it('静止データから高い stillness を返す', () => {
      const frames = generateStillFrames(/* 2秒分 */);
      const features = MotionAnalyzer.extractFeatures(frames, 2000);
      expect(features.stillness).toBeGreaterThan(0.8);
    });
  });
});
```

### モック方針

```typescript
// Claude API: msw でモック
// Firestore: Firebase Emulator Suite（@firebase/rules-unit-testing）
// TF.js: 推論結果の固定値をモック

const mockClassify = vi.fn().mockReturnValue({
  groove: 0.8, hype: 0.2, chill: 0.1,
  immersion: 0.1, hit: 0.3, afterglow: 0.0,
});
```

---

## コードレビュー基準

### レビューポイント

**機能性**:
- [ ] PRD の受け入れ条件を満たしているか
- [ ] センサー系のエッジケース（センサー許可拒否・デスクトップアクセス）が考慮されているか
- [ ] LLM 障害時のフォールバックがあるか

**可読性**:
- [ ] 命名が具体的か（`data` より `sensorFrames`、`result` より `howCard`）
- [ ] コメントは WHY のみか（WHAT は書かない）

**セキュリティ**:
- [ ] API キーがコードにハードコードされていないか
- [ ] ユーザー入力が LLM system プロンプトに混入していないか
- [ ] Firestore セキュリティルールが設定されているか

### レビューコメントの書き方

```markdown
[必須] この実装だとセンサー許可を拒否した場合にクラッシュします。
try-catch でラップして、フォールバック UI を表示してください。

[提案] `reactions.filter(r => r.scores.groove > 0.5)` より
`filterDominantReactions(reactions, 'groove', 0.5)` と名前付き関数にすると
意図が伝わりやすくなりそうです。

[質問] ここで `await` が必要な理由はなんでしょうか？
`Promise` を返していないように見えます。
```

---

## 開発環境セットアップ

### 必要なツール

| ツール | バージョン | インストール方法 |
|--------|-----------|-----------------|
| Node.js | v20 LTS | `nodenv install 20` or nvm |
| pnpm | 9.x | `npm install -g pnpm` |
| gcloud CLI | latest | [公式](https://cloud.google.com/sdk/docs/install) |
| Firebase CLI | latest | `npm install -g firebase-tools` |

### セットアップ手順

```bash
# 1. リポジトリのクローン
git clone https://github.com/engineer-guild-hackathon-2026-05/team-10.git
cd team-10

# 2. 依存関係のインストール
pnpm install

# 3. 環境変数の設定
cp apps/api/.env.example apps/api/.env
cp apps/web/.env.example apps/web/.env.local
# .env ファイルを編集（ANTHROPIC_API_KEY, Firebase 設定など）

# 4. Firebase Emulator 起動（開発時の Firestore）
firebase emulators:start --only firestore,auth

# 5. 開発サーバー起動
pnpm dev    # web(3000) + api(8080) 同時起動
```

### iOS でのセンサーテスト

1. Mac と iPhone を同じ Wi-Fi に接続
2. `pnpm dev` で起動後、iPhone の Safari から `http://[MacのIP]:3000` にアクセス
3. HTTPS でないとセンサーが動かないため、`ngrok http 3000` で HTTPS 化推奨

### AI 活用ログの記録

**Claude を使った作業は必ず `AI_USAGE_LOG.md` に記録する**。
審査の「AI 活用度」評価の根拠資料になる。最低 1 日 3 件以上。

```markdown
| 日時 | 担当 | 利用ツール | 用途 | 効果 |
|------|------|-----------|------|------|
| 5/24 14:00 | @username | Claude Code | MotionAnalyzer 実装 | 特徴量抽出のアルゴリズム設計を支援 |
```
