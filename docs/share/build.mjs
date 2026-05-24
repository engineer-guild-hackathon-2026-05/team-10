#!/usr/bin/env node
// docs/*.md を読み込み、単一の共有用リッチ HTML を生成する。
// 使い方: node docs/share/build.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const docsDir = join(here, '..');

const DOCS = [
  { id: 'prd', icon: '📋', label: 'プロダクト要求 (PRD)', file: 'product-requirements.md' },
  { id: 'func', icon: '🧩', label: '機能設計', file: 'functional-design.md' },
  { id: 'arch', icon: '🏗️', label: 'アーキテクチャ', file: 'architecture.md' },
  { id: 'repo', icon: '📁', label: 'リポジトリ構造', file: 'repository-structure.md' },
  { id: 'dev', icon: '🛠️', label: '開発ガイドライン', file: 'development-guidelines.md' },
  { id: 'glossary', icon: '📖', label: '用語集', file: 'glossary.md' },
];

// script タグ内に安全に埋め込むためのエスケープ
const escapeForScript = (s) => s.replace(/<\/script>/gi, '<\\/script>');

const docBlocks = DOCS.map((d) => {
  const md = readFileSync(join(docsDir, d.file), 'utf8');
  return `<script type="text/markdown" id="src-${d.id}">\n${escapeForScript(md)}\n</script>`;
}).join('\n');

const navButtons = DOCS.map(
  (d, i) =>
    `<button class="nav-item${i === 0 ? ' active' : ''}" data-doc="${d.id}">
      <span class="nav-icon">${d.icon}</span><span>${d.label}</span>
    </button>`
).join('\n');

const docMeta = JSON.stringify(DOCS.map(({ id, icon, label }) => ({ id, icon, label })));

const html = `<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>HowTune — 開発ドキュメント</title>
<link rel="preconnect" href="https://fonts.googleapis.com" />
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet" />
<script src="https://cdn.jsdelivr.net/npm/marked@12/marked.min.js"></script>
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
  window.__mermaid = mermaid;
</script>
<style>
  :root {
    --bg: #fafafa; --surface: #ffffff; --border: #e4e4e7; --text: #18181b;
    --muted: #71717a; --accent: #6366f1; --accent-soft: #eef2ff;
    --code-bg: #f4f4f5; --sidebar-bg: #ffffff;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #09090b; --surface: #18181b; --border: #27272a; --text: #f4f4f5;
      --muted: #a1a1aa; --accent: #818cf8; --accent-soft: #1e1b4b;
      --code-bg: #1f1f23; --sidebar-bg: #0c0c0e;
    }
  }
  * { box-sizing: border-box; }
  html { scroll-behavior: smooth; }
  body {
    margin: 0; font-family: 'Inter', system-ui, sans-serif; background: var(--bg);
    color: var(--text); display: flex; min-height: 100vh; line-height: 1.7;
    -webkit-font-smoothing: antialiased;
  }
  /* Sidebar */
  .sidebar {
    width: 280px; background: var(--sidebar-bg); border-right: 1px solid var(--border);
    padding: 28px 18px; position: sticky; top: 0; height: 100vh; overflow-y: auto;
    flex-shrink: 0;
  }
  .brand { display: flex; align-items: center; gap: 10px; padding: 0 10px 22px; }
  .brand-logo {
    width: 38px; height: 38px; border-radius: 10px;
    background: linear-gradient(135deg, #6366f1, #a855f7);
    display: grid; place-items: center; font-size: 20px; flex-shrink: 0;
  }
  .brand-title { font-weight: 800; font-size: 18px; letter-spacing: -0.02em; }
  .brand-sub { font-size: 11px; color: var(--muted); font-weight: 500; }
  .nav-label {
    font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.08em;
    color: var(--muted); padding: 8px 12px;
  }
  .nav-item {
    display: flex; align-items: center; gap: 11px; width: 100%; text-align: left;
    padding: 10px 12px; margin: 2px 0; border: none; border-radius: 9px;
    background: transparent; color: var(--text); font-size: 14px; font-weight: 500;
    font-family: inherit; cursor: pointer; transition: all 0.15s;
  }
  .nav-item:hover { background: var(--accent-soft); }
  .nav-item.active { background: var(--accent); color: #fff; }
  .nav-icon { font-size: 16px; }
  /* Main */
  main {
    flex: 1; max-width: 880px; margin: 0 auto; padding: 56px 48px 120px; width: 100%;
  }
  .doc-tag {
    display: inline-block; font-size: 12px; font-weight: 600; color: var(--accent);
    background: var(--accent-soft); padding: 4px 12px; border-radius: 999px;
    margin-bottom: 18px;
  }
  article { animation: fade 0.3s ease; }
  @keyframes fade { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: none; } }
  /* Markdown typography */
  article h1 { font-size: 32px; font-weight: 800; letter-spacing: -0.03em; margin: 0 0 24px; line-height: 1.25; }
  article h2 {
    font-size: 23px; font-weight: 700; letter-spacing: -0.02em; margin: 44px 0 16px;
    padding-bottom: 10px; border-bottom: 1px solid var(--border);
  }
  article h3 { font-size: 18px; font-weight: 700; margin: 30px 0 12px; }
  article h4 { font-size: 15px; font-weight: 700; margin: 22px 0 8px; color: var(--muted); }
  article p { margin: 14px 0; }
  article a { color: var(--accent); text-decoration: none; }
  article a:hover { text-decoration: underline; }
  article ul, article ol { padding-left: 24px; margin: 14px 0; }
  article li { margin: 6px 0; }
  article strong { font-weight: 700; }
  article code {
    font-family: 'JetBrains Mono', monospace; font-size: 13px; background: var(--code-bg);
    padding: 2px 6px; border-radius: 5px;
  }
  article pre {
    background: var(--code-bg); border: 1px solid var(--border); border-radius: 12px;
    padding: 18px; overflow-x: auto; margin: 18px 0;
  }
  article pre code { background: none; padding: 0; font-size: 13px; line-height: 1.6; }
  article blockquote {
    border-left: 3px solid var(--accent); padding: 4px 18px; margin: 18px 0;
    color: var(--muted); background: var(--accent-soft); border-radius: 0 8px 8px 0;
  }
  article table {
    width: 100%; border-collapse: collapse; margin: 18px 0; font-size: 14px;
    display: block; overflow-x: auto;
  }
  article th, article td { border: 1px solid var(--border); padding: 9px 13px; text-align: left; }
  article th { background: var(--code-bg); font-weight: 600; }
  article tr:nth-child(even) td { background: color-mix(in srgb, var(--code-bg) 40%, transparent); }
  article hr { border: none; border-top: 1px solid var(--border); margin: 36px 0; }
  .mermaid {
    background: var(--surface); border: 1px solid var(--border); border-radius: 12px;
    padding: 22px; margin: 20px 0; text-align: center; overflow-x: auto;
  }
  /* Mobile */
  .menu-toggle { display: none; }
  @media (max-width: 860px) {
    body { flex-direction: column; }
    .sidebar {
      width: 100%; height: auto; position: relative; border-right: none;
      border-bottom: 1px solid var(--border);
    }
    main { padding: 32px 22px 80px; }
    .nav-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 4px; }
  }
</style>
</head>
<body>
<aside class="sidebar">
  <div class="brand">
    <div class="brand-logo">🎵</div>
    <div>
      <div class="brand-title">HowTune</div>
      <div class="brand-sub">開発ドキュメント</div>
    </div>
  </div>
  <div class="nav-label">Documents</div>
  <nav class="nav-grid">
    ${navButtons}
  </nav>
</aside>
<main>
  <span class="doc-tag" id="doc-tag">Document</span>
  <article id="content"></article>
</main>

${docBlocks}

<script type="module">
  const DOCS = ${docMeta};
  const renderer = new marked.Renderer();
  const baseCode = renderer.code.bind(renderer);
  renderer.code = function (code, lang) {
    const text = typeof code === 'object' ? code.text : code;
    const language = typeof code === 'object' ? code.lang : lang;
    if (language === 'mermaid') {
      return '<div class="mermaid">' + text + '</div>';
    }
    return baseCode(code, lang);
  };
  marked.setOptions({ renderer, gfm: true, breaks: false });

  const isDark = window.matchMedia('(prefers-color-scheme: dark)').matches;

  function renderDoc(id) {
    const meta = DOCS.find((d) => d.id === id);
    const src = document.getElementById('src-' + id).textContent;
    document.getElementById('content').innerHTML = marked.parse(src);
    document.getElementById('doc-tag').textContent = meta.icon + '  ' + meta.label;
    document.querySelectorAll('.nav-item').forEach((b) =>
      b.classList.toggle('active', b.dataset.doc === id)
    );
    window.scrollTo({ top: 0, behavior: 'instant' });
    runMermaid();
  }

  async function runMermaid() {
    const m = window.__mermaid;
    if (!m) { setTimeout(runMermaid, 100); return; }
    m.initialize({ startOnLoad: false, theme: isDark ? 'dark' : 'default', securityLevel: 'loose' });
    const nodes = document.querySelectorAll('.mermaid');
    if (nodes.length) {
      try { await m.run({ nodes }); } catch (e) { console.warn('mermaid', e); }
    }
  }

  document.querySelectorAll('.nav-item').forEach((b) =>
    b.addEventListener('click', () => {
      renderDoc(b.dataset.doc);
      history.replaceState(null, '', '?doc=' + b.dataset.doc);
    })
  );
  const wanted = new URLSearchParams(location.search).get('doc');
  const initial = DOCS.some((d) => d.id === wanted) ? wanted : DOCS[0].id;
  renderDoc(initial);
</script>
</body>
</html>`;

writeFileSync(join(here, 'index.html'), html, 'utf8');
console.log('✅ docs/share/index.html を生成しました（' + (html.length / 1024).toFixed(0) + ' KB）');
