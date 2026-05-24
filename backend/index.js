require('dotenv').config();
const express = require('express');
const cors = require('cors');
const Anthropic = require('@anthropic-ai/sdk');

const app = express();
app.use(cors());
app.use(express.json());

const anthropic = new Anthropic.default({ apiKey: process.env.ANTHROPIC_API_KEY });

// POST /sessions/:id/chat
app.post('/sessions/:id/chat', async (req, res) => {
  const { startTime, tags, intensity, lyric, history = [] } = req.body;

  const systemPrompt = buildSystemPrompt({ startTime, tags, intensity, lyric });
  const messages = history.length > 0 ? history : [
    { role: 'user', content: '対話を開始してください' }
  ];

  try {
    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-6',
      max_tokens: 256,
      system: systemPrompt,
      messages,
      tools: [chatTool],
      tool_choice: { type: 'tool', name: 'chat_response' },
    });

    const toolUse = response.content.find(b => b.type === 'tool_use');
    if (!toolUse) throw new Error('tool_use block not found');

    res.json({ question: toolUse.input.question, choices: toolUse.input.choices ?? [] });
  } catch (err) {
    console.error(err?.message ?? err);
    res.status(500).json({ error: 'AI応答に失敗しました' });
  }
});

// ヘルスチェック
app.get('/health', (_, res) => res.json({ status: 'ok' }));

function buildSystemPrompt({ startTime, tags, intensity, lyric }) {
  const time = formatTime(startTime);
  const tagStr = (tags ?? []).join(', ') || '不明';
  const lyricStr = lyric ? `「${lyric}」` : '（歌詞情報なし）';
  return `あなたは音楽リスナーの身体反応を言語化する対話AIです。
ユーザーは${time}あたりで身体が反応しました（強度${Math.round((intensity ?? 0) * 100)}%、タグ: ${tagStr}）。
歌詞: ${lyricStr}

以下のルールで問いかけてください：
- 断定しない。「〜でしたか？」「〜でしょうか？」の確認形で問いかける
- 1回の返答は1文の問いかけのみ
- 選択肢は2〜4個。どれも正解がないような自然な選択肢にする
- 深掘りするたびに具体性を上げていく
- 日本語で返答する`;
}

const chatTool = {
  name: 'chat_response',
  description: 'ユーザーへの問いかけと選択肢を返す',
  input_schema: {
    type: 'object',
    properties: {
      question: { type: 'string', description: '確認形の問いかけ文（1文）' },
      choices: {
        type: 'array',
        items: { type: 'string' },
        description: '選択肢（2〜4個）',
      },
    },
    required: ['question', 'choices'],
  },
};

function formatTime(sec) {
  const m = Math.floor(sec / 60);
  const s = Math.floor(sec % 60);
  return `${m}:${String(s).padStart(2, '0')}`;
}

const PORT = process.env.PORT ?? 3000;
app.listen(PORT, () => console.log(`backend listening on :${PORT}`));
