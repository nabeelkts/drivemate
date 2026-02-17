## Problem Statement

The Flutter project fails to build on Android with two main issues:
1. `[!] Your app is using an unsupported Gradle project.`
2. `e: ... MainActivity.kt:3:8 Unresolved reference 'io'.`

This indicates that while the plugin is detected, it's not correctly injecting Flutter dependencies into the `:app` module, likely due to a non-standard Gradle structure or version conflicts.

## Requirements

1. Fix the "unsupported Gradle project" warning.
2. Resolve `io.flutter` and `FlutterFragmentActivity` references in `MainActivity.kt`.
3.### Phase 3: Kotlin Compilation Fix
- [ ] Downgrade AGP and Kotlin to stable versions (AGP 8.3.0, Kotlin 1.9.22)
- [ ] Move all plugin declarations to `android/settings.gradle`
- [ ] Remove `buildscript` from `android/build.gradle`
- [ ] Run `flutter build apk --debug` to verify
4. Standardize Gradle versions (AGP, Kotlin) to stable releases.
5. Clean up `android/build.gradle` by moving plugin declarations to `settings.gradle`.

## Non-Requirements

- Upgrading the Android Gradle Plugin (AGP) version (unless strictly necessary).
- Changing Kotlin or Java versions.
