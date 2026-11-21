# KursorQR

An open-source, free-to-use, **100% GDPR-compliant** dynamic QR code and smart mobile app store redirection platform — built to run at **\$0/month on the Firebase Spark Plan**.

**Live App & Redirector:** https://kursorqr.web.app

## Architecture

- **Unified Single Domain (`https://kursorqr.web.app`)**:
  - `/` → Public **KursorQR Flutter Web App** (landing page + instant QR generator + free multi-user workspace).
  - `/r/<slug>` → Rewritten by Firebase Hosting straight to **`app/web/r.html`** (~8.8 KB pure vanilla HTML/JS) — bypassing Flutter completely for near-instant mobile redirects.
- **\$0 Firebase Spark Plan Only**: Firebase Hosting, Firebase Auth, and Cloud Firestore free tier — **zero Cloud Functions**.
- **100% GDPR Compliant**: Zero cookies, zero `localStorage`, zero IP logging, zero personal data collected from QR scanners. Only anonymous aggregate counters (`totalScans`, `iosScans`, `androidScans`) are incremented.
- **Multi-Tenant Security (`firestore.rules`)**:
  - Public single-document `get` on `qr_links/{slug}` for anonymous redirects (no collection scraping).
  - Signed-in users can list, edit, and delete **only their own** QR links (`ownerId == request.auth.uid`).
  - Anonymous updates are restricted strictly to `+1` integer increments on `totalScans`, `iosScans`, and `androidScans`.

## Project Structure

```text
KursorQR/
├── .firebaserc                   # Firebase project (`kursorqr`)
├── firebase.json                 # Unified Hosting (/r/** -> /r.html, ** -> /index.html) & Firestore rules
├── firestore.rules               # Multi-tenant owner isolation + anonymous +1 scan counter rules
├── firestore.indexes.json
└── app/                          # Main KursorQR Flutter Web SaaS App
    ├── pubspec.yaml
    ├── web/
    │   ├── index.html            # Public SaaS web shell
    │   ├── manifest.json
    │   └── r.html                # <15KB vanilla HTML/JS GDPR redirect engine
    ├── lib/
    │   ├── main.dart             # Landing page, instant QR sandbox, Auth, multi-user dashboard, QR Studio
    │   └── utils/
    │       ├── file_downloader.dart
    │       ├── file_downloader_stub.dart
    │       └── file_downloader_web.dart
    └── test/
        └── widget_test.dart
```

## Build & Deploy

```bash
cd app
flutter pub get
flutter build web --release
cd ..

firebase deploy --only hosting,firestore:rules
```
