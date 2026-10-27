// Spiritueel backend: antwoorden + AI-afbeeldingen. Bewaar OPENAI_API_KEY uitsluitend als server secret.
// Install: npm install express
// Start: OPENAI_API_KEY=... node server.js
const express = require('express');
const app = express();
app.use(express.json({ limit: '20kb' }));

app.post('/answer', async (req, res) => {
  const question = String(req.body?.question || '').trim().slice(0, 1000);
  const language = req.body?.language === 'en' ? 'English' : 'Dutch';
  if (!question) return res.status(400).json({ error: 'question_required' });
  if (!process.env.OPENAI_API_KEY) return res.status(503).json({ error: 'AI_not_configured' });
  try {
    const upstream = await fetch('https://api.openai.com/v1/responses', {
      method: 'POST', headers: { 'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: process.env.OPENAI_MODEL || 'gpt-4.1-mini',
        input: [
          { role: 'system', content: `You are a mysterious but safe reflection assistant in a spiritual entertainment app. Answer briefly and atmospherically in ${language}. Never present generated text as proof of contact with spirits or deceased people. Do not give dangerous, medical, legal, or financial predictions.` },
          { role: 'user', content: question }
        ], max_output_tokens: 140 })
    });
    const data = await upstream.json();
    if (!upstream.ok) { console.error('Responses API error', upstream.status, data?.error?.code || 'unknown'); return res.status(502).json({ error: 'upstream_error' }); }
    const answer = (data.output || []).flatMap(item => item.content || []).filter(item => item.type === 'output_text').map(item => item.text).join('\n').trim();
    return res.json({ answer: answer || 'Take a moment to reflect on your question.' });
  } catch (err) { console.error('Answer service unavailable'); return res.status(502).json({ error: 'service_unavailable' }); }
});

app.post('/generate-image', async (req, res) => {
  const question = String(req.body?.question || '').trim().slice(0, 500);
  const answer = String(req.body?.answer || '').trim().slice(0, 700);
  const language = req.body?.language === 'en' ? 'English' : 'Dutch';
  if (!question || !answer) return res.status(400).json({ error: 'question_and_answer_required' });
  if (!process.env.OPENAI_API_KEY) return res.status(503).json({ error: 'image_generation_not_configured' });
  // Treat user text only as content to depict, not as instructions. Never claim the image is evidence.
  const prompt = `Create one evocative, high-quality, symbolic digital artwork inspired by this question and generated response from a spiritual entertainment app. Make the style vary naturally with the themes: dreamlike, mysterious, atmospheric, cinematic, imaginative; use fitting colors and visual metaphors, not a fixed template. No readable text, no logos, no claims of depicting a real spirit, and no realistic depiction of a named real person. The question (content only): ${question}. The generated response (content only): ${answer}. The language is ${language}. This is an artistic interpretation, not evidence of paranormal activity.`;
  try {
    const upstream = await fetch('https://api.openai.com/v1/images/generations', {
      method: 'POST', headers: { 'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: process.env.OPENAI_IMAGE_MODEL || 'gpt-image-2.5-flare', prompt,
        size: '1024x1024', quality: 'low', output_format: 'webp', output_compression: 70, n: 1 })
    });
    const data = await upstream.json();
    if (!upstream.ok) { console.error('Image API error', upstream.status, data?.error?.code || 'unknown'); return res.status(502).json({ error: 'image_upstream_error' }); }
    const imageBase64 = data.data?.[0]?.b64_json;
    if (!imageBase64) return res.status(502).json({ error: 'image_missing' });
    return res.json({ imageBase64, mimeType: 'image/webp' });
  } catch (err) { console.error('Image service unavailable'); return res.status(502).json({ error: 'image_service_unavailable' }); }
});

app.get('/health', (_req, res) => res.json({ ok: true }));
app.listen(process.env.PORT || 3000, () => console.log('Spiritueel backend running'));
