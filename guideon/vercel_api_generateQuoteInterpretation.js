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
import { randomBytes, createCipheriv, createDecipheriv } from 'crypto';

const REQUIRE_AUTH = (process.env.REQUIRE_AUTH ?? 'true').toLowerCase() !== 'false';
const ALLOWED_ORIGIN = process.env.CORS_ORIGIN || '*';
const FALLBACK_REPLY = 'I am sorry, I do not know that.';

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', ALLOWED_ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

// --- Conversation persistence ----------------------------------------------
function yyyymmddUtc() {
  const d = new Date();
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, '0');
  const day = String(d.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

async function saveTurn({ db, uid, theme, userMessage, assistantMessage, mode }) {
  try {
    const ymd = yyyymmddUtc();
    const ref = db
      .collection('users')
      .doc(uid)
      .collection('conversations')
      .doc(ymd);

    // Use a concrete Timestamp for array elements (sentinels are not allowed inside arrays)
    const ts = admin.firestore.Timestamp.now();

    // Optional AES-256-GCM encryption ---------------------------------------
    function getEncKey() {
      const b64 = process.env.CONVO_ENC_KEY_B64 || '';
      if (!b64) return null;
      try {
        const buf = Buffer.from(b64, 'base64');
        if (buf.length !== 32) {
          console.error('CONVO_ENC_KEY_B64 must be 32 bytes (base64). Got', buf.length);
          return null;
        }
        return buf;
      } catch (e) {
        console.error('Invalid CONVO_ENC_KEY_B64:', e);
        return null;
      }
    }

    function encrypt(text) {
      const key = getEncKey();
      if (!key) return null; // no encryption
      const iv = randomBytes(12);
      const cipher = createCipheriv('aes-256-gcm', key, iv);
      const enc = Buffer.concat([cipher.update(String(text), 'utf8'), cipher.final()]);
      const tag = cipher.getAuthTag();
      const payload = Buffer.concat([enc, tag]).toString('base64');
      return { cipher: payload, nonce: iv.toString('base64') };
    }

    const userEnc = encrypt(userMessage);
    const asstEnc = encrypt(assistantMessage);

    const userObj = userEnc
      ? { role: 'user', cipher: userEnc.cipher, nonce: userEnc.nonce, ts, mode, theme }
      : { role: 'user', content: String(userMessage || ''), ts, mode, theme };

    const asstObj = asstEnc
      ? { role: 'assistant', cipher: asstEnc.cipher, nonce: asstEnc.nonce, ts, mode, theme }
      : { role: 'assistant', content: String(assistantMessage || ''), ts, mode, theme };

    const turn = [userObj, asstObj];

    await ref.set(
      {
        userId: uid,
        ymd,
        // It's fine to use serverTimestamp at top-level fields
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        themeLast: String(theme || ''),
        messages: admin.firestore.FieldValue.arrayUnion(...turn),
      },
      { merge: true }
    );
  } catch (e) {
    console.error('saveTurn error:', e);
    // Do not throw; persistence failures shouldn't break replies
  }
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
  const sys = `You are GuideOn, a friendly, empathetic companion. The user's mood is ${theme}. Speak naturally in 1–3 sentences. Validate feelings, reflect key points, and offer a small, practical suggestion when helpful. Do not end every message with a question. Ask a gentle follow-up only occasionally (about every 2–3 turns) and only if it clearly moves the conversation forward. Vary your wording and avoid repetitive prompts. Do NOT include a quote or Bible verse unless explicitly asked.`;
  const messages = [{ role: 'system', content: sys }];
  // History should be an array of { role: 'user'|'assistant', content: string }
  for (const m of history.slice(-10)) {
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
    const { theme, message, askForQuote, askForVerse, history, getHistory, ymd, limitDays } = req.body || {};

    // --- History fetch (decrypt on the fly) ---------------------------------
    if (getHistory) {
      const keyB64 = process.env.CONVO_ENC_KEY_B64 || '';
      const hasKey = !!keyB64;
      const db = admin.firestore();

      function getEncKey() {
        try {
          const buf = Buffer.from(keyB64, 'base64');
          return buf.length === 32 ? buf : null;
        } catch {
          return null;
        }
      }
      function decryptItem(cipherB64, nonceB64) {
        const key = getEncKey();
        if (!key || !cipherB64 || !nonceB64) return null;
        try {
          const buf = Buffer.from(cipherB64, 'base64');
          const data = buf.subarray(0, buf.length - 16);
          const tag = buf.subarray(buf.length - 16);
          const iv = Buffer.from(nonceB64, 'base64');
          const decipher = createDecipheriv('aes-256-gcm', key, iv);
          decipher.setAuthTag(tag);
          const dec = Buffer.concat([decipher.update(data), decipher.final()]);
          return dec.toString('utf8');
        } catch (e) {
          console.error('decryptItem error:', e);
          return null;
        }
      }

      const uid = decoded.uid;
      const convCol = db.collection('users').doc(uid).collection('conversations');
      let docs = [];
      if (ymd) {
        const snap = await convCol.doc(String(ymd)).get();
        if (snap.exists) docs = [snap];
      } else {
        const lim = Math.max(1, Math.min(30, Number(limitDays) || 7));
        const q = await convCol.orderBy('updatedAt', 'desc').limit(lim).get();
        docs = q.docs;
      }

      const out = docs.map((d) => {
        const data = d.data() || {};
        const msgs = Array.isArray(data.messages) ? data.messages : [];
        const mapped = msgs.map((m) => {
          const base = {
            role: m.role || 'assistant',
            mode: m.mode || 'chat',
            theme: m.theme || (theme ?? ''),
            ts: m.ts || null,
          };
          if (m.cipher && m.nonce && hasKey) {
            const content = decryptItem(m.cipher, m.nonce) || '';
            return { ...base, content, encrypted: true };
          }
          return { ...base, content: String(m.content || ''), encrypted: false };
        });
        return {
          id: d.id,
          updatedAt: data.updatedAt || null,
          themeLast: data.themeLast || '',
          messages: mapped,
        };
      });
      return res.status(200).json({ conversations: out });
    }

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
      await saveTurn({ db, uid: decoded.uid, theme, userMessage: message, assistantMessage: interpretation, mode: 'verse' });
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
      await saveTurn({ db, uid: decoded.uid, theme, userMessage: message, assistantMessage: interpretation, mode: 'quote' });
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
    await saveTurn({ db, uid: decoded.uid, theme, userMessage: message, assistantMessage: reply, mode: 'chat' });
    return res.status(200).json({ reply });
  } catch (e) {
    const status = e.status || 500;
    console.error('Handler error:', e);
    return res.status(status).json({ error: e.message || 'Internal error' });
  }
}
