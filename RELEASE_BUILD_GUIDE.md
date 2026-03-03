# Release Build Setup Guide

## Problem Solved ✅
Fixed: "APK or Android App Bundle was signed in debug mode" error

## What Was Changed

### 1. Updated `android/app/build.gradle.kts`
- Added keystore loading configuration
- Created release signing config
- Changed release build to use release signing instead of debug

### 2. Created `android/key.properties`
- Contains your keystore credentials
- **IMPORTANT:** This file is in `.gitignore` - never commit it!

### 3. Updated `.gitignore`
- Added `*.jks`, `*.keystore`, `key.properties` to prevent committing sensitive files

---

## Next Steps

### Step 1: Create Your Keystore

Run this command in PowerShell (replace `YourUsername` with your actual Windows username):

```powershell
keytool -genkey -v -keystore C:\Users\YourUsername\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**You'll be asked to:**
1. Enter a password (storePassword)
2. Re-enter the password (for keyPassword)
3. Answer some questions (name, organization, etc.) - these can be anything

**⚠️ IMPORTANT:** 
- Remember your passwords! You'll need them every time you build
- Store the keystore file safely - if you lose it, you can't update your app on Play Store

### Step 2: Update `android/key.properties`

Open `android/key.properties` and replace the placeholder values:

```properties
storePassword=THE_PASSWORD_YOU_JUST_CREATED
keyPassword=THE_SAME_PASSWORD
keyAlias=upload
storeFile=C:\\Users\\YourUsername\\upload-keystore.jks
```

**Note:** Use double backslashes `\\` in the path on Windows!

### Step 3: Build Release App Bundle

Now build your release-signed app bundle:

```bash
flutter build appbundle --release
```

The output will be at:
```
build/app/outputs/bundle/release/app-release.aab
```

### Step 4: Upload to Play Store

Upload the `app-release.aab` file to Google Play Console - it will now be properly signed!

---

## Testing Locally

To test a release APK on your device:

```bash
flutter build apk --release
```

Output location:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## Troubleshooting

### Error: "Keystore file not found"
- Check the path in `key.properties` is correct
- Make sure to use double backslashes: `C:\\Users\\Name\\file.jks`

### Error: "Invalid keystore password"
- Double-check your password in `key.properties`
- Passwords are case-sensitive

### Error: "Key alias not found"
- Make sure the `keyAlias` matches what you created
- Default is `upload` in this guide

---

## Important Notes

1. **Never lose your keystore!** If you lose it, you cannot update your app on Play Store
2. **Backup your keystore** to a secure location (cloud storage, external drive, etc.)
3. **Never commit** keystore files or `key.properties` to Git
4. **Use different keystores** for different apps (don't reuse across projects)

---

## Quick Reference

| Command | Purpose | Output Location |
|---------|---------|-----------------|
| `flutter build apk --release` | Test release APK | `build/app/outputs/flutter-apk/app-release.apk` |
| `flutter build appbundle --release` | Play Store upload | `build/app/outputs/bundle/release/app-release.aab` |

---

## Files Modified

✅ `android/app/build.gradle.kts` - Added release signing configuration  
✅ `android/key.properties` - Created (you need to fill in passwords)  
✅ `.gitignore` - Added keystore files to ignore list  
