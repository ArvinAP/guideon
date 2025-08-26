// Temporary Vercel API file (copy-paste into your Vercel project as api/generateQuoteInterpretation.js)
// Features:
// - Verifies Firebase ID token from Authorization: Bearer <token>
// - CORS handling
// - Quote mode: fetches a themed quote from Firestore and asks DeepSeek for an interpretation + action step
// - Bible verse mode: on explicit request, fetches a themed verse and asks DeepSeek for an empathetic interpretation + gentle practice
// - Chat mode: no new quote; uses history + theme to produce a short, empathetic reply
//
// Required Vercel env vars:
//   FIREBASE_PROJECT_ID
//   FIREBASE_CLIENT_EMAIL
//   FIREBASE_PRIVATE_KEY   (with literal \n for newlines)
//   DEEPSEEK_API_KEY
//   REQUIRE_AUTH=true      (optional, defaults to true)
//   CORS_ORIGIN=*          (optional; set to your app origin in prod)

import admin from 'firebase-admin';

const REQUIRE_AUTH = (process.env.REQUIRE_AUTH ?? 'true').toLowerCase() !== 'false';
const ALLOWED_ORIGIN = process.env.CORS_ORIGIN || '*';
const FALLBACK_REPLY = 'I am sorry, I do not know that.';

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', ALLOWED_ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

function initAdmin() {
  if (admin.apps.length) return;
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n');
  if (!projectId || !clientEmail || !privateKey) {
    console.error('Missing Firebase service account env vars');
    throw new Error('Service account misconfigured');
  }
  admin.initializeApp({
    credential: admin.credential.cert({ projectId, clientEmail, privateKey }),
    projectId,
  });
}

async function verifyIdToken(req) {
  if (!REQUIRE_AUTH) return { uid: 'dev-bypass' };
  const auth = req.headers['authorization'] || '';
  const m = auth.match(/^Bearer (.+)$/i);
  if (!m) throw Object.assign(new Error('Missing Authorization header'), { status: 401 });
  const idToken = m[1];
  try {
    return await admin.auth().verifyIdToken(idToken);
  } catch (e) {
    e.status = 401;
    throw e;
  }
}

async function getRandomQuoteByTheme(db, theme) {
  const q = await db.collection('quotes').where('themes', 'array-contains', theme.toLowerCase()).get();
  if (q.empty) return null;
  const docs = q.docs;
  const pick = docs[Math.floor(Math.random() * docs.length)];
  const data = pick.data();
  return {
    text: data.text || '',
    source: data.source || '',
    verse: data.verse || '',
    theme: theme.toLowerCase(),
  };
}

async function getRandomVerseByTheme(db, theme) {
  // Expect collection 'verses' with fields: text, reference (e.g., "John 3:16"), translation, themes: string[]
  const q = await db.collection('verses').where('themes', 'array-contains', theme.toLowerCase()).get();
  if (q.empty) {
    // Fallback: try any verse if theme not found
    const any = await db.collection('verses').limit(50).get();
    if (any.empty) return null;
    const docs = any.docs;
    const pick = docs[Math.floor(Math.random() * docs.length)];
    const d = pick.data();
    return {
      text: d.text || '',
      reference: d.reference || '',
      translation: d.translation || '',
      theme: theme.toLowerCase(),
    };
  }
  const docs = q.docs;
  const pick = docs[Math.floor(Math.random() * docs.length)];
  const data = pick.data();
  return {
    text: data.text || '',
    reference: data.reference || '',
    translation: data.translation || '',
    theme: theme.toLowerCase(),
  };
}

function buildChatMessagesForQuote({ theme, message, quote }) {
  const sys = `You are GuideOn, an empathetic, concise mental-health companion. The user's mood is ${theme}. Use the quote to give a short, validating interpretation and ONE practical action step. Avoid sounding clinical; be warm and brief.`;
  const user = `User message: ${message}\nQuote: "${quote.text}" — ${quote.source || 'Unknown'}${quote.verse ? ` (${quote.verse})` : ''}`;
  return [
    { role: 'system', content: sys },
    { role: 'user', content: user },
  ];
}

function buildChatMessagesForConversation({ theme, history = [], message }) {
  const sys = `You are GuideOn, an empathetic, concise companion. The user's mood is ${theme}. Respond briefly (1-3 sentences), validate feelings, and ask ONE gentle follow-up. Do NOT provide a quote unless explicitly asked.`;
  const messages = [{ role: 'system', content: sys }];
  // History should be an array of { role: 'user'|'assistant', content: string }
  for (const m of history.slice(-8)) {
    if (!m || !m.role || !m.content) continue;
    const role = m.role === 'assistant' ? 'assistant' : 'user';
    messages.push({ role, content: String(m.content).slice(0, 2000) });
  }
  messages.push({ role: 'user', content: String(message).slice(0, 2000) });
  return messages;
}

async function deepseekChat(messages) {
  const apiKey = process.env.DEEPSEEK_API_KEY;
  if (!apiKey) throw Object.assign(new Error('Missing DEEPSEEK_API_KEY'), { status: 500 });

  const resp = await fetch('https://api.deepseek.com/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: 'deepseek-chat',
      messages,
      temperature: 0.7,
      max_tokens: 400,
    }),
  });

  if (!resp.ok) {
    const text = await resp.text();
    throw Object.assign(new Error(`DeepSeek error ${resp.status}: ${text}`), { status: 502 });
  }
  const json = await resp.json();
  const content = json.choices?.[0]?.message?.content?.trim() || '';
  return content;
}

function buildChatMessagesForVerse({ theme, message, verse }) {
  const sys = `You are GuideOn, an empathetic, concise companion. The user's mood is ${theme}. Use the Bible verse to offer a short, compassionate interpretation (2-5 sentences max) and ONE gentle, practical application. Be sensitive and non-preachy, welcoming users of varying beliefs.`;
  const ref = [verse.reference, verse.translation].filter(Boolean).join(' ');
  const user = `User message: ${message}\nBible verse: "${verse.text}"${ref ? ` — ${ref}` : ''}`;
  return [
    { role: 'system', content: sys },
    { role: 'user', content: user },
  ];
}

export default async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  try {
    initAdmin();
    const decoded = await verifyIdToken(req);
    const { theme, message, askForQuote, askForVerse, history } = req.body || {};

    if (!theme || !message) {
      return res.status(400).json({ error: 'Missing theme or message' });
    }

    const db = admin.firestore();

    if (askForVerse) {
      const verse = await getRandomVerseByTheme(db, String(theme));
      if (!verse) return res.status(404).json({ error: `No verses available${theme ? ` for theme: ${theme}` : ''}` });

      const messages = buildChatMessagesForVerse({ theme, message, verse });
      let interpretation = '';
      try {
        interpretation = await deepseekChat(messages);
      } catch (_) {
        interpretation = FALLBACK_REPLY;
      }
      if (!interpretation) interpretation = FALLBACK_REPLY;
      return res.status(200).json({ verse, interpretation });
    }

    if (askForQuote) {
      const quote = await getRandomQuoteByTheme(db, String(theme));
      if (!quote) return res.status(404).json({ error: `No quotes for theme: ${theme}` });

      const messages = buildChatMessagesForQuote({ theme, message, quote });
      let interpretation = '';
      try {
        interpretation = await deepseekChat(messages);
      } catch (_) {
        interpretation = FALLBACK_REPLY;
      }
      if (!interpretation) interpretation = FALLBACK_REPLY;
      return res.status(200).json({ quote, interpretation });
    }

    // Chat mode (no new quote)
    const messages = buildChatMessagesForConversation({ theme, history, message });
    let reply = '';
    try {
      reply = await deepseekChat(messages);
    } catch (_) {
      reply = FALLBACK_REPLY;
    }
    if (!reply) reply = FALLBACK_REPLY;
    return res.status(200).json({ reply });
  } catch (e) {
    const status = e.status || 500;
    console.error('Handler error:', e);
    return res.status(status).json({ error: e.message || 'Internal error' });
  }
}
