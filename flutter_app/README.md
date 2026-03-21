# Red Alert TV – Flutter

Flutter rewrite of the RedAlertTV Android app.
Polls the Pikud HaOref (Home Front Command) API every second and displays live rocket/missile alerts.

## Features

| Feature | Details |
|---------|---------|
| **Live alert polling** | Queries `oref.org.il` every second with correct browser headers |
| **Alert display** | Full-screen animated banner with title, affected cities in columns, and a 20-second countdown |
| **Google Maps** | Dedicated map tab shows red markers on all currently-affected cities |
| **Adaptive UI** | Detects Android TV (`FEATURE_LEANBACK`) and renders a TV-optimised landscape layout; falls back to a standard mobile layout |
| **Multi-language** | Hebrew (RTL), English, Russian, Arabic |
| **Test mode** | Injects a dummy alert so you can preview the UI without a real siren |

## Project layout

```
flutter_app/
├── lib/
│   ├── main.dart                    # App entry-point; detects TV/mobile
│   ├── models/
│   │   ├── alert.dart               # Alert data model + DummyAlert
│   │   └── city_coordinates.dart    # Hardcoded lat/lng for ~60 Israeli cities
│   ├── services/
│   │   ├── alert_service.dart       # HTTP fetch + BOM handling
│   │   └── platform_service.dart    # MethodChannel → isAndroidTV()
│   ├── providers/
│   │   └── alert_provider.dart      # ChangeNotifier, 1-second Timer
│   ├── l10n/
│   │   └── strings.dart             # he / en / ru / ar string map
│   ├── screens/
│   │   └── home_screen.dart         # TV layout + Mobile layout + 4 tabs
│   └── widgets/
│       ├── alert_banner.dart        # Animated full-screen alert overlay
│       └── alert_map.dart           # GoogleMap with alert markers
└── android/
    └── app/src/main/
        ├── AndroidManifest.xml      # INTERNET permission + TV banner
        └── kotlin/…/MainActivity.kt # FlutterActivity + isAndroidTV channel
```

## Getting started

### Prerequisites

- Flutter SDK ≥ 3.10
- Android SDK (API 21+)
- A Google Maps API key with the **Maps SDK for Android** enabled

### 1. Clone and install dependencies

```bash
cd flutter_app
flutter pub get
```

### 2. Set your Maps API key

Edit `android/app/src/main/AndroidManifest.xml` and replace `YOUR_MAPS_API_KEY`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_REAL_KEY_HERE" />
```

### 3. Configure local.properties

```bash
cp android/local.properties.example android/local.properties
# then edit the file with your SDK paths
```

### 4. Run

```bash
# Debug on a connected device or emulator
flutter run

# Release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Android TV debug
flutter run -d <tv-device-id>
```

## API notes

Endpoint: `GET https://www.oref.org.il/WarningMessages/alert/alerts.json`

Required headers (without these the request is blocked):

```
Referer: https://www.oref.org.il/
X-Requested-With: XMLHttpRequest
User-Agent: <any modern browser UA>
```

- **No alert** → empty body (or UTF-8 BOM only) → `AlertService` returns `null`
- **Active alert** → JSON with `id`, `cat`, `title`, `data[]`, `desc`

The `id` field is tracked in `AlertProvider` so the same alert isn't re-rendered on every poll tick.

## Building a release APK

```bash
cd flutter_app
flutter build apk --release --split-per-abi
```

The resulting APK files are in:
```
build/app/outputs/flutter-apk/
  app-arm64-v8a-release.apk   ← modern Android TV boxes
  app-armeabi-v7a-release.apk
  app-x86_64-release.apk
```

> **Note:** You will need a signing keystore for a production release. See
> [Flutter deployment docs](https://docs.flutter.dev/deployment/android).
