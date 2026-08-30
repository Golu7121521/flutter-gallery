# Gallery

A Flutter gallery app that scans and displays all photos & videos on the device.

Package name: `com.gallery`

## Features implemented
- Splash screen → permission screen → home
- Auto scans all device photos/videos on launch (via `photo_manager`)
- Light & dark theme (also "follow system") — toggle from Settings
- Compact floating bottom tab bar: Recent / Photos / Videos / Favorites + a separate 3-dot menu button
  - 3-dot menu → Trash bin, Settings, About
- Settings: gesture control on/off, autoplay-next on/off, theme mode
- Full-screen photo viewer with pinch-to-zoom (`photo_view`), swipe between photos
- Full-screen video player with:
  - progress bar, play/pause, next/previous
  - double-tap left/right to seek ±10s
  - press & hold for 2x speed
  - rotate button, playback-speed menu
  - swipe gestures for volume (right half) & brightness (left half) — togglable in Settings
- Transparent icon-only bottom action bar on viewers: Share, Edit (Crop / Draw), Favorite, Delete (with confirmation dialog), More (Set as wallpaper, Details)
- Trash bin screen (soft-trash tracking + permanent delete flow via `photo_manager`)
- About screen with user agreement / privacy text

## Getting started

1. Install Flutter (stable channel) if you haven't already: https://docs.flutter.dev/get-started/install
2. Unzip this project and open it in Android Studio / VS Code, or via terminal:
   ```bash
   cd gallery_app
   flutter pub get
   ```
3. `android/local.properties` is intentionally **not included** (and is git-ignored) since it
   contains machine-specific SDK paths. Android Studio creates it automatically the first
   time you open the project. If you build from the terminal instead, create it manually:
   ```
   sdk.dir=/path/to/your/Android/sdk
   flutter.sdk=/path/to/your/flutter
   ```
4. This repo also does not ship a committed Gradle wrapper (`gradlew`/`gradle-wrapper.jar`),
   so CI regenerates it automatically (see `.github/workflows/build.yml`). For local builds,
   generate it once with:
   ```bash
   cd android && gradle wrapper --gradle-version 8.9 --distribution-type all && cd ..
   ```
   (or simply open the project in Android Studio, which does this for you automatically).
5. Run on a connected device or emulator:
   ```bash
   flutter run
   ```

### iOS
Only a minimal `Info.plist` is included. To get a complete buildable iOS project,
run the following once inside the project folder (requires Xcode & CocoaPods):
```bash
flutter create --platforms=ios .
```
This regenerates the full `ios/` Xcode project while keeping the Dart code and
`com.gallery` bundle id intact (make sure to set the Bundle Identifier to
`com.gallery` in Xcode afterwards, and re-check the permission strings already
provided in `ios/Runner/Info.plist`).

## CI/CD (GitHub Actions)
A ready-to-use workflow is included at `.github/workflows/build.yml`:
- Triggers on every push to `main` (and manual dispatch)
- Uses `ubuntu-latest`, JDK 17 (Zulu) via `actions/setup-java@v3`, and
  `subosito/flutter-action@v2` for the Flutter SDK
- Regenerates the Gradle wrapper on the runner, runs `flutter pub get`,
  builds a **release APK**, and uploads it as a workflow artifact
  (`gallery-release-apk`) — download it from the run's **Artifacts** section.

### Build configuration
- Android Gradle Plugin: **8.7.3** / Gradle **8.9**
- Kotlin Android Gradle plugin: **1.9.24**
- `compileSdk` / `targetSdk`: **36**
- `minSdk`: **24** (required for `video_player` / modern gallery packages)
- Java / Kotlin JVM target: **17**

## Notes
- Some features (Set as wallpaper) depend on OS version/manufacturer support. Renaming media files is
  not supported since `photo_manager` v3.12.0 removed `setTitle` from `AssetEntity` — this feature was
  intentionally removed to keep the app compiling against the latest package.
- Video "Edit" is intentionally limited to photo crop/draw as per typical gallery app UX;
  extend `video_view_screen.dart` if you'd like video trimming as well.
- Gesture control, autoplay, and theme preferences persist via `shared_preferences`.
