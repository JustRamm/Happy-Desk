<p align="center">
  <img src="assets/brand/U&ME.svg" width="200" alt="U&ME Logo"/>
</p>

<h3 align="center">U & ME (Happy Desk)</h3>
<p align="center">Workplace Joy & Emotional Wellbeing, Reinvented.</p>

---

## What is U & ME?

**U & ME** (formerly Happy Desk) is a comprehensive workplace emotional wellbeing, attendance, and team engagement platform built with Flutter and Supabase. Born from a partnership with **Mind Empowered (ME)**, U & ME aims to champion mental health, self-awareness, and team resilience in modern workplaces.

---

## Key Features & Capabilities

- **Real Device GPS Clock-In / Clock-Out**:
  - Automatically queries device GPS hardware on Clock-In via `Geolocator`.
  - Reverse-geocodes exact coordinates to human-readable street/city locations via Nominatim OpenStreetMap API.
  - Persists real location data (`lat`, `lng`, `location_name`, `country`, `state`, `district`, `pincode`) in Supabase `work_sessions`.

- **Mochi AI Wellness Companion**:
  - Powered by Google Gemini AI API with CBT (Cognitive Behavioral Therapy) reframing.
  - Features natural multi-message response delivery (splits long replies into up to 3 sequential messages with 400ms typing cadence).
  - Dynamic personalized greeting pairs and intelligent crisis handling (detects family emergencies & sickness with deep human empathy).

- **Founder & Leader Analytics Portal**:
  - Live employee work hours analytics and real-time clock-in/out tracking.
  - **Pending Leave Approvals Portal**: View real employee leave applications submitted to Supabase `leave_requests` and approve or reject them instantly.
  - Generate & manage unique Company Join Codes and Team Leader Join Codes.

- **NGL Anonymous Venting & Joy Jar**:
  - Send private, anonymous appreciation notes directly to teammates' jars.
  - Shred stress text into paper strips in the private Venting Vault.

- **Weekly Hero Shoutouts**:
  - Peer nominations and voting for weekly workplace heroes.

- **Coffee Break Resets & Scheduler**:
  - Group and 1-on-1 coffee break invites sent directly to team feeds.

- **About U & ME & Mind Empowered**:
  - Learn about Mind Empowered (ME), co-founders Maya Menon and Srila Menon, core pillars (Self-Awareness, Self-Expression, Self-Sufficiency), and Lead Developer Abiram T. Bijoy.

- **Clean Emoji-Free UI & Custom Avatars**:
  - 100% emoji-free interface with custom material icons and typography.
  - Real camera & gallery avatar photo uploads stored directly in Supabase Storage with dynamic initials fallback.

---

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend & Auth**: Supabase (Database, Auth, Storage, Realtime)
- **AI Companion**: Google Gemini 1.5 Pro API with CBT Prompts
- **Location & Maps**: Geolocator (GPS) & Nominatim OpenStreetMap (Reverse Geocoding)
- **Typography & Theme**: Google Fonts (Plus Jakarta Sans, Be Vietnam Pro)
- **Audio & SVGs**: `flutter_svg`, `audioplayers`

---

## Project Structure

```
lib/
├── screens/          # Application screens (Mochi AI, Founder Analytics, Home, About, Auth)
├── widgets/          # Reusable UI components (Modals, Navigation Bar, Cards)
├── services/         # Supabase API, User Preferences, Sound, Mochi Prompt Services
├── theme/            # Curated color tokens, typography, and theme standards
assets/
├── brand/            # U&ME logo, Mochi SVG artwork
├── about/            # Mind Empowered & developer brand assets
assets/prompts/       # Mochi system prompts and config schemas
assets/supabase_schema.sql # Complete Supabase SQL migration script
```

---

## Getting Started

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run application locally
flutter run -d chrome    # or Android emulator / physical device

# 3. Build Release APK (arm64-v8a)
flutter build apk --release --split-per-abi --no-tree-shake-icons
```

---

*Developed by the Mind Empowered Dev Team led by Abiram T. Bijoy.*
