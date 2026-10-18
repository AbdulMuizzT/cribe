const GEMINI_MODEL = 'gemini-2.5-flash';
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

async function callGemini(prompt) {
  const response = await fetch(GEMINI_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-goog-api-key': process.env.GEMINI_API_KEY,
    },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0.7 },
    }),
  });

  if (!response.ok) {
    const text = await response.text().catch(() => '');
    throw new Error(`Gemini responded ${response.status}: ${text}`);
  }

  const data = await response.json();
  const text = (data?.candidates?.[0]?.content?.parts || []).map((p) => p.text || '').join('');
  if (!text) throw new Error('Gemini returned an empty response.');
  return text;
}

/// Gemini sometimes wraps JSON in ```json fences or adds stray text —
/// pull out just the {...} object.
function extractJson(text) {
  const cleaned = text.replace(/```json/gi, '').replace(/```/g, '').trim();
  const start = cleaned.indexOf('{');
  const end = cleaned.lastIndexOf('}');
  if (start === -1 || end === -1) throw new Error('No JSON object found in Gemini response.');
  return JSON.parse(cleaned.slice(start, end + 1));
}

async function generateCatalog({ name, material, craft, origin, category }) {
  const prompt = `You are helping an Indian artisan list a handmade product on an e-commerce catalog.

Product name: ${name}
Category: ${category || 'Handicraft'}
Material: ${material || 'N/A'}
Craft technique: ${craft || 'N/A'}
Origin: ${origin || 'India'}

Write a warm, appealing product description (2-3 sentences) that highlights the
craftsmanship, material and origin. Then translate that exact description into
natural, fluent Hindi and natural, fluent Tamil (not machine-literal — write
how a native speaker would). Also suggest 5 short lowercase SEO keywords.

Respond with ONLY a JSON object in this exact shape, no extra commentary, no
markdown fences:
{
  "descriptionEnglish": "...",
  "descriptionHindi": "...",
  "descriptionTamil": "...",
  "keywords": ["...", "...", "...", "...", "..."]
}`;

  const raw = await callGemini(prompt);
  const parsed = extractJson(raw);

  return {
    en: parsed.descriptionEnglish || '',
    hi: parsed.descriptionHindi || '',
    ta: parsed.descriptionTamil || '',
    keywords: Array.isArray(parsed.keywords) ? parsed.keywords : [],
  };
}

async function generateBusinessAnswer({ question, language, artisanName, products }) {
  const productLines = (products && products.length)
    ? products.map((p) => `- ${p.name} (${p.category || 'product'}), ₹${p.price ?? '?'}, status: ${p.status || 'draft'}`).join('\n')
    : '- No products listed yet.';

  const prompt = `You are CribeIt's AI Business Manager — a friendly, practical advisor helping an
Indian artisan named ${artisanName} run their handmade-goods business on the CribeIt app.

Their current products:
${productLines}

The artisan asks: "${question}"

Give a helpful, specific, encouraging answer in 3-5 sentences, referencing their actual products
by name where relevant (for example, suggesting which one to promote, how to price it, or writing
a short ad for it if asked). Respond in ${language}. Plain conversational text only, no markdown,
no headers, no bullet points.`;

  return await callGemini(prompt);
}

module.exports = { generateCatalog, generateBusinessAnswer };
