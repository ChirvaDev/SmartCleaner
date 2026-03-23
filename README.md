# Smart Cleaner — Visual Similarity Search & Media Cleanup

A test assignment iOS app for cleaning and organizing media files on iPhone.

<p align="center">
  <img src="847_1x_shots_so.png" width="100%" alt="Smart Cleaner App Screenshots">
</p>

**Requirements:**
iOS 16+
SwiftUI 
No third-party dependencies

---

## Features

| Category | Algorithm | Media Type |
|---|---|---|
| Duplicate Photos | creationDate + pixelSize grouping (Exact match)| Photos |
| Similar Photos | Visual Similarity (Vision Framework) + Smart Caching | Photos |
| Screenshots | PHAssetMediaSubtype.photoScreenshot | Photos |
| Live Photos | PHAssetMediaSubtype.photoLive | Photos |
| Screen Recordings | PHAssetMediaSubtype.videoScreenRecording | Videos |
| Similar Videos | duration + resolution grouping | Videos |

---

## Media Filtering Approaches

### Duplicate Photos
Groups photos by combining `creationDate` (rounded to second) and `pixelWidth × pixelHeight`. Two photos are considered duplicates if they share the same creation timestamp and pixel dimensions. This is an O(n) dictionary-based approach that requires no image loading — all data comes directly from `PHAsset` metadata.

### Similar Photos
Groups photos using visual similarity analysis (Vision Framework). The system generates high-dimensional feature prints to compare image content, detecting similar compositions or poses regardless of the exact capture time. This approach identifies visually related photos that metadata-only filtering might miss.

> For production, full perceptual hashing (pHash via `vDSP`) can be enabled. The infrastructure is already implemented in `PerceptualHashService.swift`.

### Screenshots
Fetches photos filtered by `PHAssetMediaSubtype.photoScreenshot` — a native Photos framework subtype. No custom logic required.

### Live Photos
Fetches photos filtered by `PHAssetMediaSubtype.photoLive`. Displayed with a Live Photo badge indicator. Note: Live Photos are only available on real devices — the simulator does not support them.

### Screen Recordings
Fetches videos filtered by `PHAssetMediaSubtype.videoScreenRecording`. Displayed with a duration badge.

### Similar Videos
Groups videos by `duration` (rounded to nearest second) + `pixelWidth × pixelHeight`. Two videos are considered similar if they have the same length and resolution. O(n) dictionary-based, no file loading required.
---

## Architecture

```
SmartCleaner/
├── App/
│   ├── SmartCleanerApp.swift
│   └── ContentView.swift
├── Core/
│   ├── Services/
│   │   ├── ThumbnailCache.swift      # PHCachingImageManager + NSCache (50MB)
│   │   └── GalleryCache.swift        # UserDefaults persistence between sessions
│   ├── Components/
│   │   ├── CategoryHeaderView.swift
│   │   ├── DeleteButtonView.swift
│   │   ├── LoadingView.swift
│   │   ├── EmptyStateView.swift
│   │   ├── ScaleButtonStyle.swift
│   │   └── PageIndicatorView.swift
│   └── Extensions/
│       └── Color+Theme.swift
└── Features/
    ├── Onboarding/
    ├── Media/                        # Main screen (6-category grid)
    ├── DuplicatePhotos/
    ├── SimilarPhotos/
    ├── Screenshots/
    ├── LivePhotos/
    ├── ScreenRecordings/
    └── SimilarVideos/
```

Each feature follows **MVVM**:
```
Feature/
├── Model/
├── ViewModel/
└── View/
```

---

## Performance

**Thumbnail loading**
- `PHCachingImageManager` prefetches thumbnails as groups become visible
- `NSCache` (300 images / 50MB) prevents redundant requests
- `Task.cancel()` on `onDisappear` — no wasted work during fast scrolling

**Gallery cache**
- Grouping results are persisted to `UserDefaults` as `[[localIdentifier]]`
- On relaunch: cached data shown **instantly**, fresh grouping runs in background
- Cache is invalidated after any delete operation

**Grouping algorithms**
- All 6 categories use O(n) or O(n log n) algorithms
- No image loading required for grouping (metadata only)
- Runs on `Task.detached(priority: .userInitiated)` — never blocks the main thread

---

## Permissions

`NSPhotoLibraryUsageDescription` is required in `Info.plist`.

Photo library access is requested at the end of onboarding. The app handles all authorization states: `.authorized`, `.limited`, `.denied`, `.restricted`.
