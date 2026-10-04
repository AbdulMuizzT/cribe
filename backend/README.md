# CribeIt Backend

A small Express server that gives the Flutter app **real** AI for three features:

| Endpoint | Feature | Powered by |
|---|---|---|
| `POST /api/enhance` | AI Image Studio (background removal / photo enhancement) | remove.bg |
| `POST /api/catalog` | AI Catalog generation **and** Hindi/Tamil translation | Google Gemini |
| `POST /api/voice` | Voice Assistant (speech-to-text) | AssemblyAI |

Smart Pricing stays a local rule-based calculation — there's no real free API for
artisan market pricing, so faking one would be worse than being upfront about it.

## 1. Get your three free API keys

### remove.bg (image enhancement)
1. Go to **https://www.remove.bg/api** and click "Get API Key" (sign up with
   email or Google — no credit card required for the free tier).
2. Once logged in, go to your **Dashboard → API Key** page.
3. Click the key to reveal it, then copy it.
4. Paste it into `backend/.env` as:
   ```
   REMOVE_BG_API_KEY=paste_it_here
   ```

### Google Gemini (catalog generation + translation)
1. Go to **https://aistudio.google.com/apikey**.
2. Sign in with a Google account, click **"Create API key"**.
3. Copy the key it shows you (starts with `AIza...`).
4. Paste it into `backend/.env` as:
   ```
   GEMINI_API_KEY=paste_it_here
   ```

### AssemblyAI (voice transcription)
1. Go to **https://www.assemblyai.com/dashboard/signup** and sign up.
2. You'll land on the **Dashboard → API Keys** page — your key is shown right there.
3. Copy it.
4. Paste it into `backend/.env` as:
   ```
   ASSEMBLYAI_API_KEY=paste_it_here
   ```

All three keys go in the **same file**: `backend/.env`.

## 2. Set up and run the backend

```bash
cd backend
cp .env.example .env
# now open .env in any text editor and paste your 3 keys in (step 1 above)

npm install
npm start
```

You should see:
```
CribeIt backend listening on http://localhost:3000
Keys loaded: { REMOVE_BG_API_KEY: true, GEMINI_API_KEY: true, ASSEMBLYAI_API_KEY: true }
```
If any key shows `false`, double-check you pasted it into `.env` (not `.env.example`)
and restart (`npm start`) — Node only reads `.env` once, at startup.

## 3. Point the Flutter app at this backend

Open `lib/services/api_service.dart` in the Flutter project and check this line:

```dart
const String kBackendBaseUrl = 'http://10.0.2.2:3000';
```

- **Android emulator** running on the same computer as this backend: leave it
  as-is. `10.0.2.2` is a special address that always means "the host machine"
  from inside the Android emulator.
- **Physical Android phone**: replace `10.0.2.2` with your computer's LAN IP
  address (e.g. `http://192.168.1.42:3000`). Find it with `ipconfig` (Windows)
  or `ifconfig`/`ip addr` (Mac/Linux). Your phone and computer must be on the
  same Wi-Fi network, and this backend must be running.

Also see the root `README.md` for a required one-line Android manifest change
(`usesCleartextTraffic`) — without it, Android blocks the app from talking to
a plain `http://` backend at all.

## Quick manual test (optional, before wiring up the app)

```bash
# Catalog generation + translation
curl -X POST http://localhost:3000/api/catalog \
  -H "Content-Type: application/json" \
  -d '{"name":"Handwoven Cotton Saree","material":"100% Cotton","craft":"Handwoven","origin":"Madurai, Tamil Nadu","category":"Traditional Textiles"}'

# Image enhancement (replace with a real file path)
curl -X POST http://localhost:3000/api/enhance -F "image=@/path/to/photo.jpg" -o enhanced.png

# Voice transcription (replace with a real short audio file)
curl -X POST http://localhost:3000/api/voice -F "audio=@/path/to/clip.m4a"
```

## Free-tier limits to know about

- **remove.bg**: ~50 free preview-quality calls/month on the free plan.
- **Gemini (2.5 Flash)**: free tier is rate-limited (a handful of requests per
  minute, a few hundred per day) — check your usage at
  https://aistudio.google.com if calls start failing with a 429.
- **AssemblyAI**: generous free trial credit, pay-as-you-go after.

All three failure modes (missing key, exhausted quota, no internet) are
handled gracefully by the Flutter app — it falls back to the original
simulated demo behaviour instead of crashing, and shows a small note saying
so on screen.
