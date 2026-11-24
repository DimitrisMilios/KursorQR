# KursorQR · Claymorphism Redesign, Clean MVVM & Optimization Guide

Branch: `feat/claymorphism-redesign`
Scope: Complete visual, motion, 3D Blender asset, Clean MVVM, and Flutter Web performance overhaul of KursorQR with a custom tactile claymorphism design system.
Invariants: Firebase Spark Auth & EU Cloud Firestore schema, `firestore.rules`, 10-QR server-enforced quota, zero-cookie GDPR architecture, `/r/<slug>` `<15KB` budget, and high-res QR PNG export fidelity (`QrRenderService`) remain 100% preserved.

---

## Part A · Target Look & Design Tokens

### A.1 Core Claymorphism Rules

- **Opaque, matte, warm clay surfaces**: Zero `BackdropFilter` blur, zero `Border.all` on UI chrome, zero Material splashes (`NoSplash.splashFactory`).
- **Depth via light, not lines**: Raised surfaces paint an outer floating shadow + inner top-left highlight + inner bottom-right shade (`ClayDecoration`). Pressed controls physically sink (lift collapses to 2, inner shadows invert, fill darkens 6%). Inputs, lists, and progress tracks sit inside sunken `ClayWell`s.
- **Chunky, friendly geometry**: `16 / 24 / 32 / 40 px` radii, pill buttons, rounded **Nunito** typography (`google_fonts`), tabular figures for scan counters/quotas, monospace for `/r/<slug>` links and hex inputs.
- **Color discipline**: **Action = Forest Green (`primary`)**, **Selected / Highlight CTA = Gold (`gold`)**, **Danger = Coral (`coral`)**.
- **Anti-clutter**: Pills/chips are permitted **only when interactive**. Static decorative badges are removed; exclamation marks are removed from all user-facing strings and toasts.

### A.2 Palette (`app/lib/core/constants/app_colors.dart` — Deep Rust & Pearl)

- Base: `sand` `#EAE0C8` (Pearl), `sandDeep` `#DFD3B6`, `clay` `#F7F1E3`, `clayDeep` `#E3D7BC`
- Lighting: `clayLight` `#FFFFFF`, `clayShade` `#5C1F02`, `clayShadow` `#5C1F02`
- Primary: `primary` `#8B3103` (Deep Rust), `primaryDeep` `#5C1F02`, `primaryLight` `#C45722`, `mint` `#F0D6C4`
- Accent: `gold` `#DFA94B`, `goldDeep` `#B88329`, `goldLight` `#FAD284`, `butter` `#F9EAC8`
- Semantic: `coral` `#D9534F`, `coralDeep` `#B53531`, `coralSoft` `#F9D8D6`, `sage` `#5C8D6B`
- Text: `textPrimary` `#2C1608`, `textSecondary` `#5E3A24`, `textMuted` `#8E6E58`, `textOnPrimary` `#FFFFFF`

### A.3 Spacing & Radii (`app/lib/core/constants/app_dimensions.dart`)

- `navbarHeight = 72.0`, `maxContentWidth = 1160.0`
- `radiusClaySm = 16.0`, `radiusClay = 24.0`, `radiusClayLg = 32.0`, `radiusClayXl = 40.0`
- `clayDepth = 6.0`, `clayLift = 18.0`

---

## Part B · Clean MVVM Architecture

Strict unidirectional dependency flow:

- `Views & Clay Widgets` → `ViewModels (ChangeNotifier)` → `Repositories & Services` → `Models & Firebase`
- Zero `firebase_auth` or `cloud_firestore` imports inside `lib/views/` or `lib/widgets/`.
- Zero `BuildContext` or `ScaffoldMessenger` references inside `lib/viewmodels/`, `lib/repositories/`, or `lib/services/`.
- `app.dart` wires dependencies via `MultiProvider` and routes screens declaratively; views subscribe to narrow state slices via `Selector` / scoped `Consumer`s to eliminate unnecessary full-tree rebuilds.
- Dedicated ViewModels:
  - `AuthViewModel` — Firebase Auth session, email verification, GDPR Art. 17 erasure
  - `AuthFormViewModel` — Sign-in / create-account mode, validation, visibility, password reset
  - `LandingViewModel` — GDPR notice dismissal & instant sandbox orchestration
  - `DashboardViewModel` — On-demand Spark fetch, quota, KPIs, search filtering, GDPR Art. 20 JSON export
  - `QrLinkFormViewModel` — Random slug generation, URL/slug validation, create/update submission
  - `QrStudioViewModel` — Colors, linear gradients, built-in icons, local logo memory buffer, PNG export

---

## Part C · Procedural Blender 5.2 3D Clay Assets (`tools/blender/`)

`tools/blender/render_clay_assets.py` builds all 18 KursorQR assets procedurally from primitives using Principled BSDF clay (`roughness 0.65`, `subsurface 0.08`, 3-segment bevels, top-left 400W 5200K / bottom-right 120W 7000K area lights, Khronos PBR Neutral + hex calibration pass) and saves a local (gitignored) `tools/blender/kursorqr_clay.blend` scene.

`tools/blender/optimize_web_assets.py` re-encodes 16-bit renders into 8-bit max-compression PNGs and lossless WebP for `hero_qr_scene.webp` (verifying max diff `<= 1/255`), and generates `app/web/favicon.png` and PWA icons from `kursorqr_logo_3d.png`.

Assets in `app/assets/clay/`:
- `kursorqr_logo_3d.png` (512 px)
- `hero_qr_scene.webp` (720×560 lossless WebP)
- `feature_routing.png`, `feature_studio.png`, `feature_gdpr.png` (56 px @ 2×)
- `metric_links.png`, `metric_scans.png`, `metric_ios.png`, `metric_android.png` (40 px @ 2×)
- `empty_qr_links.png` (200 px @ 2×)
- `verify_envelope.png` (88 px @ 2×)
- `icon_studio.png`, `icon_link.png`, `icon_account.png`, `icon_shield.png` (40 px @ 2×)
- `toast_check.png`, `toast_error.png` (28 px @ 2×)
- `grain_tile.png` (256×256 seamless)

---

## Part D · Motion & Jelly Physics (`app/lib/core/motion/clay_motion.dart`)

- Springs: `snappy (520/32)`, `bouncy (300/18)`, `liquid (180/14)`, `gentle (160/24)`, `still (520/60)`.
- `ClayMotionScope` respects `MediaQuery.disableAnimations`.
- `JellyTransform` lazily allocates unbounded spring controllers for out-of-phase X/Y squash & stretch (16 ms offset), velocity skew, hover rotation wobble, and optional 3 px damped-sine surface outline ripple.
- `HeroQrRender` plays 2 gentle arrival float cycles and rests until hovered; tilts up to 4° toward pointer and squashes on click.
- `ClayStagger` (35 ms step) choreographs landing features, dashboard KPIs/cards, and dialog children.

---

## Part E · Full Performance & Web Optimization

1. **GPU-fast ClayDecoration**: Analytic `drawRRect` / `clipRRect` only, constant blur sigmas, `RepaintBoundary` isolation on heavy surfaces.
2. **Zero idle tickers**: Lazy controller creation in `JellyTransform`, bounded hero float, `TickerMode(enabled: false)` on hidden panels.
3. **Zero full-screen `Opacity` layers**: Grain tile uses `Image.asset(..., opacity: const AlwaysStoppedAnimation(0.02))`.
4. **DPR-aware texture decoding**: `cacheWidth` clamped to `(displayWidth * dpr).round()` on all 3D clay assets.
5. **Icon badge caching**: `QrRenderService` caches rendered center-icon PNG bytes keyed by `(iconId, fg, fgEnd, useGradient, direction, bg)`.
6. **Web delivery**: Preconnect hints + CSS bobbing HTML splash in `web/index.html`; `tools/fingerprint_web.mjs` content-hashed `app/<hash>/` asset/JS bundling; immutable `Cache-Control` headers in `firebase.json`; `r.html` kept strictly `<15KB` with zero external requests.

---

## Part F · 14-Commit Execution Plan

1. `docs: add full claymorphism redesign and MVVM optimization guide`
2. `feat(theme): add claymorphism tokens, Nunito theme, and spring motion engine`
3. `feat(ui): build reusable claymorphism widget kit and jelly physics`
4. `feat(assets): add Blender 5.2 procedural clay pipeline and render 3D assets`
5. `refactor(mvvm): extract form/landing ViewModels, ClipboardService, and icon badge cache`
6. `feat(landing): redesign landing page with floating clay navbar, 3D hero, and instant sandbox`
7. `feat(dashboard): redesign dashboard workspace with clay cards, 3D KPIs, and Selector scoping`
8. `feat(auth): redesign verify email screen and Firebase error fallback in claymorphism`
9. `feat(dialogs): redesign Auth, Link Form, Account, and GDPR dialogs with ClayDialog and ClayToast`
10. `feat(studio): redesign Branded QR Studio dialog with clay controls and color knobs`
11. `feat(web): add clay HTML splash screen, preconnects, and claymorphism r.html redirector`
12. `perf(web): add content-hash build fingerprinting and immutable Firebase cache headers`
13. `test: expand MVVM ViewModel unit tests and claymorphism widget tests`
14. `chore(qa): final polish, static audit, and release web build verification`
