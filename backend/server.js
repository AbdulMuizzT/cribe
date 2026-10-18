require('dotenv').config();
const express = require('express');
const cors = require('cors');
const multer = require('multer');

const { removeBackground } = require('./services/removeBg');
const { generateCatalog, generateBusinessAnswer } = require('./services/gemini');
const { transcribeAudio } = require('./services/assemblyai');

const app = express();
app.use(cors());
app.use(express.json({ limit: '2mb' }));

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 12 * 1024 * 1024 } });

app.get('/', (req, res) => {
  res.json({ ok: true, service: 'CribeIt backend', endpoints: ['/api/enhance', '/api/catalog', '/api/voice', '/api/assistant'] });
});

// Feature 1: AI Image Studio — real background removal / photo enhancement.
app.post('/api/enhance', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file received (multipart field name must be "image").' });
    }
    if (!process.env.REMOVE_BG_API_KEY) {
      return res.status(500).json({ error: 'REMOVE_BG_API_KEY is not set in backend/.env.' });
    }
    const pngBuffer = await removeBackground(req.file.buffer, req.file.mimetype);
    res.set('Content-Type', 'image/png');
    res.send(pngBuffer);
  } catch (err) {
    console.error('Enhance error:', err);
    res.status(502).json({ error: 'Image enhancement failed.', detail: String(err.message || err) });
  }
});

// Feature 2 (+ Hindi/Tamil translation): AI Catalog generation.
app.post('/api/catalog', async (req, res) => {
  try {
    const { name, material, craft, origin, category } = req.body || {};
    if (!name) {
      return res.status(400).json({ error: 'Missing "name" in request body.' });
    }
    if (!process.env.GEMINI_API_KEY) {
      return res.status(500).json({ error: 'GEMINI_API_KEY is not set in backend/.env.' });
    }
    const catalog = await generateCatalog({ name, material, craft, origin, category });
    res.json(catalog);
  } catch (err) {
    console.error('Catalog error:', err);
    res.status(502).json({ error: 'Catalog generation failed.', detail: String(err.message || err) });
  }
});

// AI Business Manager — Gemini-powered, business-aware chat.
app.post('/api/assistant', async (req, res) => {
  try {
    const { question, language, artisanName, products } = req.body || {};
    if (!question) {
      return res.status(400).json({ error: 'Missing "question" in request body.' });
    }
    if (!process.env.GEMINI_API_KEY) {
      return res.status(500).json({ error: 'GEMINI_API_KEY is not set in backend/.env.' });
    }
    const answer = await generateBusinessAnswer({
      question,
      language: language || 'English',
      artisanName: artisanName || 'the artisan',
      products: Array.isArray(products) ? products : [],
    });
    res.json({ answer });
  } catch (err) {
    console.error('Assistant error:', err);
    res.status(502).json({ error: 'Assistant request failed.', detail: String(err.message || err) });
  }
});

// Feature 4: Voice Assistant — real speech-to-text.
app.post('/api/voice', upload.single('audio'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No audio file received (multipart field name must be "audio").' });
    }
    if (!process.env.ASSEMBLYAI_API_KEY) {
      return res.status(500).json({ error: 'ASSEMBLYAI_API_KEY is not set in backend/.env.' });
    }
    const result = await transcribeAudio(req.file.buffer);
    res.json(result);
  } catch (err) {
    console.error('Voice error:', err);
    res.status(502).json({ error: 'Voice transcription failed.', detail: String(err.message || err) });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`CribeIt backend listening on http://localhost:${PORT}`);
  console.log('Keys loaded:', {
    REMOVE_BG_API_KEY: !!process.env.REMOVE_BG_API_KEY,
    GEMINI_API_KEY: !!process.env.GEMINI_API_KEY,
    ASSEMBLYAI_API_KEY: !!process.env.ASSEMBLYAI_API_KEY,
  });
});
