require('dotenv').config();
const express = require('express');
const cors = require('cors');
const OpenAI = require('openai');

const app = express();
app.use(cors());
app.use(express.json());

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// POST /sessions/:id/chat
app.post('/sessions/:id/chat', async (req, res) => {
  const { startTime, tags, intensity, lyric, history = [] } = req.body;

  const systemPrompt = buildSystemPrompt({ startTime, tags, intensity, lyric });
  const messages = [
    { role: 'system', content: systemPrompt },
    ...history,
  ];

  try {
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages,
      functions: [chatResponseFunction],
      function_call: { name: 'chat_response' },
      temperature: 0.8,
    });

    const args = JSON.parse(
      completion.choices[0].message.function_call.arguments
    );

    res.json({ question: args.question, choices: args.choices ?? [] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'AI応答に失敗しました' });
  }
});

// ヘルスチェック
app.get('/health', (_, res) => res.json({ status: 'ok' }));

// システムプロンプト生成
function buildSystemPrompt({ startTime, tags, intensity, lyric }) {
  const time = formatTime(startTime);
  const tagStr = (tags ?? []).join(', ') || '不明';
  const lyricStr = lyric ? `「${lyric}」` : '（歌詞情報なし）`;
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

// Function Calling スキーマ
const chatResponseFunction = {
  name: 'chat_response',
  description: 'ユーザーへの問いかけと選択肢を返す',
  parameters: {
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
