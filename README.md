# KursorQR

An open-source, free-to-use, **100% GDPR-compliant** dynamic QR code and smart mobile app store redirection platform — built with clean **MVVM architecture** to run at **\$0/month on the Firebase Spark Plan** even with thousands of users.

**Live App & Redirector:** https://kursorqr.web.app

## Highlights

- **Unified Domain (`https://kursorqr.web.app`)**:
  - `/` → Public **KursorQR Flutter Web SaaS App** (landing page + live gradient/icon QR sandbox + multi-tenant user workspace).
  - `/r/<slug>` → Rewritten by Firebase Hosting straight to **`app/web/r.html`** (~8.8 KB vanilla HTML/JS) — bypassing Flutter completely for near-instant mobile redirects.
- **Built for Thousands of Free Users on Spark Plan (\$0/month)**:
  - **Strict Server-Side 10 QR / Account Quota**: Enforced unbypassably in `firestore.rules` via atomic `WriteBatch` mutations against `users/{uid}.qrSlugs` (deleting a link atomically frees a slot; zero Cloud Functions needed).
  - **Anti-Spam Verification**: Google Sign-In works instantly (`email_verified == true`); Email/Password sign-ups verify their inbox before creating links.
  - **~90% Fewer Firestore Reads**: On-demand `.get()` on login + manual **Refresh Stats** button + optimistic local updates on Create/Edit/Delete (no persistent `snapshots()` listeners draining the 50K/day free tier).
- **Branded QR Studio (`pretty_qr_code`)**:
  - Solid colors OR **2-color Linear Gradients** (4 presets + custom hex start/end + 4 directions).
  - **Center Icon / Logo**: 16 crisp built-in vector icons OR **local custom PNG/JPG/WebP upload** processed 100% in browser memory (never uploaded to Cloud Storage).
  - Smooth, Dots, and Classic module styles, automatic contrast warning, automatic Error Correction `H (30%)` when a center icon/logo is active, persistent saved design per QR link, and 512 / 1024 / 2048px PNG export.
- **100% GDPR-Compliant & Transparent**:
  - `/r/<slug>` scanners: **0 cookies, 0 `localStorage`, 0 IP logging, 0 PII** — only anonymous `totalScans`, `iosScans`, and `androidScans` increments.
  - Web app: Zero tracking/ad cookies (strictly necessary Firebase Auth session storage only when signed in), EU `eur3` Cloud Firestore residency, full in-app Privacy & Cookie Policy, **GDPR Art. 20 JSON Data Export**, and **GDPR Art. 17 1-Click Account & Data Erasure**.

## MVVM Folder Structure

```text
KursorQR/
├── .firebaserc
├── firebase.json                     # Unified Hosting (/r/** -> /r.html, ** -> /index.html)
├── firestore.rules                   # Unbypassable 10-QR quota + verified email + anonymous +1 scan
├── firestore.indexes.json
└── app/                              # KursorQR Flutter Web App (Clean MVVM)
    ├── pubspec.yaml
    ├── web/
    │   ├── index.html
    │   ├── manifest.json
    │   └── r.html                    # 8.8 KB vanilla HTML/JS GDPR redirect engine
    ├── lib/
    │   ├── main.dart                 # Composition root & DI wiring
    │   ├── core/                     # app_config.dart, app_theme.dart, qr_icon_catalog.dart
    │   ├── models/                   # qr_link.dart, qr_design_config.dart
    │   ├── repositories/             # auth_repository.dart, qr_link_repository.dart
    │   ├── services/                 # qr_render_service.dart, file_downloader*, local_image_picker*
    │   ├── viewmodels/               # auth_viewmodel.dart, dashboard_viewmodel.dart, qr_studio_viewmodel.dart
    │   └── views/
    │       ├── landing_page.dart
    │       ├── verify_email_screen.dart
    │       ├── dashboard_screen.dart
    │       └── dialogs/              # auth_dialog, qr_link_form_dialog, qr_studio_dialog, gdpr_policy_dialog, account_settings_dialog
    └── test/
        └── widget_test.dart
```

## Build & Deploy

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter build web --release
cd ..

firebase deploy --only hosting,firestore:rules
```
