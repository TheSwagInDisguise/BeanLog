# BeanLog ☕︎

A cozy, local-first cafe coffee journal for iOS with a share-card studio.
Design direction: **Option A — "Warm Cafe Journal"** (cream paper, espresso ink, terracotta, watercolour washes, taped polaroids).

## Features
- **Journal** with polaroid thumbnails, scalloped watercolour score badges, search and filter pills (drink, Iced, Oat, 8.0+).
- **Log / Edit sheet** with cafe, drink type (Flat White, Long Black, Batch Brew, Cortado, Matcha, Custom), Hot/Iced, milk, price, a 0.0–10.0 score (slider and ±0.1 stepper), cup photo (PhotosUI library or camera), date and time, suburb (typed, or **Locate** via CoreLocation + reverse geocoding), roast/origin, tasting tags (+ custom), sweetness and acidity (1–5), and general thoughts.
- **Share Studio**:
  - 9:16 Story or 4:5 Feed card, with a toggle for each of the 13 attributes.
  - Watercolour and ink stickers plus **Add Emoji**. Drag to move, pinch to scale, two-finger twist to rotate, tap to remove (with Undo).
  - Exports a crisp 3× PNG (1080×1920 / 1080×1350) via `ImageRenderer`, to Photos or the share sheet.
- **Insights** (Swift Charts): score over time and average score by drink.
- **Backup**: export/import a `.zip` holding `backup.json` and `photos/*.jpg` (merge or replace).

## Tech
- SwiftUI + SwiftData (`@Attribute(.externalStorage)` for photos). iOS 17+.
- 100% on-device: no backend, no accounts, **no iCloud/CloudKit entitlements**.
- Zero third-party dependencies. Fonts are Fraunces and Caveat (SIL OFL, bundled and registered at runtime).
- The `.xcodeproj` uses a file-system-synchronized group, so any file you add under `BeanLog/` is picked up automatically (Xcode 16+).

## Releases / sideloading
Every push to `main` runs `.github/workflows/release-ipa.yml` on `macos-26`. It builds an unsigned archive and creates a GitHub Release tagged `v1.0.<run>-<sha>` with **`BeanLog-unsigned.ipa`** attached.
Install it with AltStore, SideStore or Sideloadly using a free Apple ID (they re-sign it).

## Design mock-ups
`mockups/preview.html` is the interactive Phase-1 prototype for all three directions (A was chosen).
