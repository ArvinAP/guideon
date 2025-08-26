import * as functionsV1 from 'firebase-functions/v1';
import admin from 'firebase-admin';

// Initialize Admin SDK once
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// Read DeepSeek API key
// 1) Preferred for emulator/CI: environment variable DEEPSEEK_API_KEY
// 2) Spark-plan friendly: Firebase Functions runtime config deepseek.key
//    Set with: firebase functions:config:set deepseek.key="sk-..."
const DEEPSEEK_API_KEY = process.env.DEEPSEEK_API_KEY || functionsV1.config().deepseek?.key;

export const generateQuoteInterpretation = functionsV1
  .region('us-central1')
  .https.onCall(async (data, context) => {
    try {
      // Auth check (optional but recommended)
      if (!context.auth) {
        throw new functionsV1.https.HttpsError(
          'unauthenticated',
          'User must be authenticated to use this function.'
        );
      }

      const { theme, message } = data || {};
      if (!theme || typeof theme !== 'string') {
        throw new functionsV1.https.HttpsError(
          'invalid-argument',
          'Missing required string parameter: theme'
        );
      }
      if (!message || typeof message !== 'string') {
        throw new functionsV1.https.HttpsError(
          'invalid-argument',
          'Missing required string parameter: message'
        );
      }

      if (!DEEPSEEK_API_KEY) {
        throw new functionsV1.https.HttpsError(
          'failed-precondition',
          'DeepSeek API key is not configured on the server.'
        );
      }

      // Fetch a random quote from Firestore based on theme
      // Expected collection structure documented in the app's README
      const quotesRef = db.collection('quotes');
      const snapshot = await quotesRef.where('themes', 'array-contains', theme.toLowerCase()).get();

      if (snapshot.empty) {
        throw new functionsV1.https.HttpsError(
          'not-found',
          `No quotes found for theme: ${theme}`
        );
      }

      const docs = snapshot.docs;
      const randomDoc = docs[Math.floor(Math.random() * docs.length)];
      const qData = randomDoc.data();

      const quoteText = qData.text || '';
      const quoteSource = qData.source || '';
      const quoteVerse = qData.verse || '';

      const systemPrompt = `You are a compassionate, concise coach. Given the user's message and a quote/verse, respond in two parts:\n\n1) A one-paragraph, friendly interpretation that relates the quote/verse to the user's situation.\n2) One practical, gentle action step they can take today.\n\nTone: warm, non-judgmental, hopeful. Keep total under 140 words.`;

      const userPrompt = `User message: "${message}"\n\nQuote/Verse: "${quoteText}"${quoteSource ? ` — ${quoteSource}` : ''}${quoteVerse ? ` (${quoteVerse})` : ''}`;

      // Call DeepSeek API
      const response = await fetch('https://api.deepseek.com/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${DEEPSEEK_API_KEY}`,
        },
        body: JSON.stringify({
          model: 'deepseek-chat',
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userPrompt },
          ],
          temperature: 0.7,
        }),
      });

      if (!response.ok) {
        const errText = await response.text();
        throw new functionsV1.https.HttpsError(
          'internal',
          `DeepSeek API error: ${response.status} ${response.statusText} ${errText}`
        );
      }

      const json = await response.json();
      const aiMessage = json?.choices?.[0]?.message?.content || '';

      return {
        quote: {
          text: quoteText,
          source: quoteSource,
          verse: quoteVerse,
          theme: theme.toLowerCase(),
        },
        interpretation: aiMessage,
      };
    } catch (err) {
      if (err instanceof functionsV1.https.HttpsError) {
        throw err;
      }
      console.error('Unhandled error in generateQuoteInterpretation', err);
      throw new functionsV1.https.HttpsError('internal', 'Unexpected error.');
    }
  });
