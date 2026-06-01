# Deployment Guide — new_kare_1

This document explains how to take the project from a fresh machine to production releases on Android, iOS, web and desktop platforms. It covers environment setup, building release artifacts, basic signing and publishing notes, and a simple CI example for Android.

Prerequisites
- Git and the repository cloned to your machine.
- Flutter SDK (stable channel recommended): https://flutter.dev/docs/get-started/install
- Platform SDKs:
  - Android: Android Studio (SDK, command line tools), ANDROID_HOME/ANDROID_SDK_ROOT configured.
  - iOS (macOS only): Xcode and Xcode command line tools.
  - For Windows/macOS/Linux desktop: platform-specific build tools (Visual Studio on Windows, Xcode on macOS, development packages on Linux).
- (Optional) Firebase CLI for web/hosting or other hosting providers.

Common setup steps
1. Install Flutter and add it to PATH. Verify with:

```bash
flutter --version
flutter doctor
```

2. From repository root install dependencies:

```bash
flutter pub get
```

3. Resolve any platform issues reported by `flutter doctor` (missing SDK components, licenses, etc.).

Android — debug and release
1. Start an emulator or connect a device to test in debug mode:

```bash
flutter run
```

2. Prepare a release build (AAB preferred for Play Store):

```bash
flutter build appbundle --release
```

3. Configure signing for Android:
  - Create a signing key (one-time):

```bash
keytool -genkey -v -keystore ~/.keystore/new_kare_key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias new_kare_key
```

  - Add signing config to `android/app/build.gradle` (or use `key.properties`) and do not commit keystore or passwords.

4. Upload the generated AAB located in `build/app/outputs/bundle/release/app-release.aab` to Google Play Console.
5. Fill store listing, content rating, pricing, and roll out a release.

iOS — debug and release (macOS required)
1. Open the iOS project in Xcode:

```bash
open ios/Runner.xcworkspace
```

2. Ensure your Apple Developer account is added in Xcode and provisioning profiles/capabilities are configured.
3. For App Store builds, increment the version and build number in `ios/Runner/Info.plist` or Xcode project settings.
4. Build and archive in Xcode (`Product > Archive`) and upload via Xcode Organizer or use `xcodebuild` + `altool`/Transporter.
5. Use TestFlight for beta distribution, then submit to App Store Connect for review.

Notes about code signing
- Do not commit certificates, keys, or provisioning profiles to the repository.
- Use environment variables or a secure secret store in CI to provide signing credentials.

Web deployment
1. Build the web app:

```bash
flutter build web --release
```

2. The production-ready static site will be in `build/web`.
3. Hosting options:
  - Firebase Hosting: `firebase deploy --only hosting` after `firebase init`.
  - Static hosts (Netlify, Vercel, GitHub Pages) — upload `build/web` contents.

Example: Deploy to Firebase Hosting

```bash
npm install -g firebase-tools
firebase login
firebase init hosting
# choose build/web as public directory
flutter build web --release
firebase deploy --only hosting
```

Windows/macOS/Linux (desktop)
1. Build Windows executable:

```bash
flutter build windows --release
```

2. Build macOS app (macOS):

```bash
flutter build macos --release
```

3. Packaging and distribution depend on the platform; consider using installers (MSIX, DMG) or platform stores.

CI/CD example (Android release via GitHub Actions)
1. Create a GitHub Actions workflow in `.github/workflows/android-release.yml` that:
  - Installs Flutter
  - Runs `flutter pub get`
  - Runs tests `flutter test`
  - Builds `flutter build appbundle --release`
  - Uploads the artifact or directly deploys using fastlane to Play Store

Minimal workflow snippet:

```yaml
name: Android Build
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
      - name: Install dependencies
        run: flutter pub get
      - name: Run tests
        run: flutter test --no-fail-on-empty-tests
      - name: Build appbundle
        run: flutter build appbundle --release
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: appbundle
          path: build/app/outputs/bundle/release/app-release.aab
```

Publishing considerations
- Play Store requires a signed AAB and store listing. Follow Google Play policies and set up app signing (Play App Signing is recommended).
- App Store requires Apple Developer Program enrollment and proper provisioning.
- For automated publishing consider `fastlane` to handle signing and upload workflows.

Security and secrets
- Keep keystores, API keys and credentials out of source control.
- Use CI secret storage (GitHub Secrets, GitLab CI variables, etc.).

Troubleshooting
- If builds fail on CI, run the same commands locally to reproduce and inspect logs.
- Use `flutter doctor -v` for diagnosing environment problems.

Final checks before release
- Run full test suite and smoke test on real devices.
- Verify analytics, crash reporting and release notes.
- Roll out releases gradually (staged rollout) and monitor crash/ANR reports.

If you want, I can:
- Add a `fastlane` configuration for automated releases.
- Create a GitHub Actions workflow tailored to your Play/App Store publishing needs.
If you want, I can:
- add a `fastlane` configuration for automated releases (added).
- create GitHub Actions workflows for Android and iOS (added):
  - `.github/workflows/android-release.yml`
  - `.github/workflows/ios-release.yml`

Usage notes
- Android workflow expects these GitHub Secrets if you want to sign and publish automatically:
  - `ANDROID_KEYSTORE_BASE64` — base64-encoded keystore file
  - `ANDROID_KEYSTORE_PASSWORD` — keystore password
  - `ANDROID_KEY_PASSWORD` — key password
  - `ANDROID_KEY_ALIAS` — key alias
  - `PLAY_STORE_JSON_KEY` — JSON service account for Play Console (optional)
  - `PUBLISH_PLAYSTORE` — set to `true` to enable the automatic publish step

- iOS fastlane lanes expect these GitHub Secrets for automated builds:
  - `MATCH_PASSWORD` — if using fastlane match for code signing
  - `APPLE_ID` — Apple ID used by fastlane
  - `APP_SPECIFIC_PASSWORD` — app-specific password for uploading builds

Security: store keystores, JSON keys and passwords as encrypted GitHub Secrets and never commit them to the repository.

---
See also: [README.md](README.md#L1) for development and repository structure.
