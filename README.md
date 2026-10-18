# CribeIt — From Craft to Commerce.

An AI-powered virtual business assistant MVP for Indian artisans, built for SIH.

**This version has a real backend** for three features — AI Image Studio
(background removal), AI Catalog generation + Hindi/Tamil translation, and
the Voice Assistant (speech-to-text) — all running on free API keys. Smart
Pricing stays a transparent local calculation (there's no honest free API for
real artisan market pricing). Every real-backend call has a graceful offline
fallback to the original simulated behaviour, so the app never breaks if the
backend isn't running or a key runs out of quota.

## What's new in this version
- **Real camera/gallery photo capture** (`image_picker`) in Add Product.
- **Real background removal** via the `backend/` server calling remove.bg.
- **Real AI catalog descriptions + Hindi/Tamil translation** via Gemini.
- **Real voice recording + transcription** (`record` package + AssemblyAI),
  with live language detection shown on screen.

## Setup — two parts

### Part A: the backend (do this first)
Full instructions, including **exactly where to copy each free API key from
and where to paste it**, are in `backend/README.md`. Short version:

```bash
cd backend
cp .env.example .env
# paste your 3 free keys into .env — see backend/README.md for exact steps
npm install
npm start
```

Leave this running in a terminal while you use the app.

### Part B: the Flutter app

```bash
# from the project root (not inside backend/)
flutter create . --project-name cribeit --org com.cribeit
flutter pub get
```

Then **two required manual edits** before camera/mic/network features work on
Android (flutter create generates a bare-bones manifest that doesn't include
these):

1. Open `android/app/src/main/AndroidManifest.xml` and add, as direct children
   of `<manifest>` (above the `<application>` tag):
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.CAMERA"/>
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   ```
2. On the `<application ...>` tag in the same file, add:
   ```xml
   android:usesCleartextTraffic="true"
   ```
   This is required because the backend runs on plain `http://` for local
   development — Android blocks non-HTTPS network calls by default from API
   28 onward. (For a real production deploy, you'd put the backend behind
   HTTPS instead of using this flag.)

3. Check `lib/services/api_service.dart` — `kBackendBaseUrl` defaults to
   `http://10.0.2.2:3000`, which works out of the box for an Android
   **emulator**. If you're using a **physical phone**, change it to your
   computer's LAN IP (see `backend/README.md`).

Then:
```bash
flutter analyze
flutter run
```

## Demo flow this build supports end-to-end
Splash → Language (English/Hindi/Tamil) → Onboarding → Home → Add Product →
**Take Photo or Upload** (real camera/gallery) → AI Image Studio (real
background removal via remove.bg, animated while it runs) → Use Enhanced
Image → AI Catalog (press **Regenerate** for a real Gemini-written
description auto-translated into Hindi & Tamil) → Voice Demo (real
microphone recording → real transcription → live detected language) →
Smart Pricing (AI Price Assistant, ₹2,850 computed from your entered costs)
→ Listing Preview (shows your real enhanced photo) → Publish → Markets (B2B
buyers + simulated ONDC/GeM connection).

## Getting it running — a note on verification
This code was written and reviewed by hand in an environment without the
Flutter SDK, Node.js, or internet access installed, so it has **not** been
run through `flutter pub get` / `flutter analyze` / `flutter run`, nor has
the backend been run against the live remove.bg / Gemini / AssemblyAI APIs.
Every file's braces/parens were checked for balance, every import verified
against the file tree, and all three external API request shapes
(remove.bg, Gemini REST, AssemblyAI upload+poll) were checked against each
service's current documentation. Please run the standard checks
(`flutter analyze`, a manual test of each backend endpoint with `curl` as
shown in `backend/README.md`) before a live demo.

## Project structure

```
backend/                    # Node/Express server — see backend/README.md
  server.js
  services/
    removeBg.js              # remove.bg background removal
    gemini.js                 # Gemini catalog generation + translation
    assemblyai.js              # AssemblyAI speech-to-text
  .env.example

lib/
  main.dart                 # entry point
  app.dart                  # MaterialApp + theme + Provider setup
  models/models.dart        # Artisan, Product (+ real photo bytes), Buyer, PricingRecommendation
  data/demo_data.dart       # seeded artisan, 5 products, 3 buyers
  services/
    demo_service.dart       # AppState (ChangeNotifier) — app logic & demo "AI"
    storage_service.dart    # shared_preferences persistence
    api_service.dart        # NEW — HTTP client for the backend's 3 endpoints
  theme/app_theme.dart      # craft-inspired color palette + Material 3 theme
  screens/                  # one file per screen
  widgets/
    ai_processing_view.dart # reusable animated "AI processing" step dialog
    craft_visual.dart       # local gradient+icon illustrated placeholder
    product_image.dart      # NEW — shows real photo if present, else placeholder
    cribeit_logo.dart       # custom-painted woven-thread mark
    product_card.dart       # reusable product list card
```

## Design notes
- Real photos (camera/gallery capture + backend-enhanced result) are kept as
  in-memory bytes on the `Product` model and are intentionally **not**
  persisted to `shared_preferences` (that store is for small JSON only) — so
  they survive the current session but reset to the illustrated placeholder
  after a full app restart. Seeded demo products still use the local
  gradient+icon placeholders when no real photo has been taken.
- Every backend call (`ApiService.*`) is wrapped in try/catch at the call
  site and shows a small on-screen note about whether it used the live
  backend or fell back to simulated behaviour — never a blank screen or a
  crash.
- Pricing is computed live from whatever Raw Material Cost / Crafting Time /
  Other Costs the user enters, landing on ₹2,850 for the seeded defaults,
  clearly labeled as a demo market analysis.
- Colors: Burgundy `#5A1F2B`, Lavender `#B8A1C8`, Ivory `#F7F1E8`, Terracotta
  `#B96E58`, Charcoal `#242126`.
