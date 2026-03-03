# Google Sign-In Troubleshooting Guide

## 🔍 Issue: Can't Login via Google in Release Build

### **Root Cause**
Your `google-services.json` file has old SHA-1 certificate fingerprints that don't match your new release keystore.

---

## ✅ Solution Steps

### **Step 1: Download Updated google-services.json**

1. **Go to Firebase Console:**
   - Open https://console.firebase.google.com/
   - Select project: **"smds-c1713"**

2. **Navigate to Project Settings:**
   - Click the **Settings gear icon** (top left)
   - Select **"Project settings"**

3. **Find Your Android App:**
   - Scroll to **"Your apps"** section
   - Look for app with package name: `com.drivemate.mds`

4. **Download Fresh Configuration:**
   - Click the **download icon** next to `google-services.json`
   - This downloads a new file with ALL your SHA-1 fingerprints included

5. **Replace Old File:**
   - Delete: `d:\mds\mds\android\app\google-services.json`
   - Copy downloaded file to: `d:\mds\mds\android\app\google-services.json`

---

### **Step 2: Verify SHA-1 Fingerprints in Firebase**

Make sure Firebase Console has these SHA-1 fingerprints:

#### **Debug SHA-1** (example format):
```
AA:BB:CC:DD:EE:... (from debug.keystore)
```

#### **Release SHA-1** (YOUR upload keystore):
```
19:76:BD:7D:98:26:62:A0:46:86:0C:13:44:21:00:E6:96:4D:9D:D6
```

#### **Play App Signing SHA-1** (if enrolled):
- Get from Play Console → Setup → App integrity

---

### **Step 3: Clean and Rebuild**

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# OR build App Bundle for Play Store
flutter build appbundle --release
```

---

### **Step 4: Test Login**

1. **Uninstall any existing version** from your device:
   ```bash
   adb uninstall com.drivemate.mds
   ```

2. **Install fresh release build:**
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

3. **Test Google Sign-In** - should work now! ✅

---

## 🚨 Common Issues & Solutions

### **Issue 1: "Sign-in failed" or "Authentication error"**

**Cause:** SHA-1 fingerprint mismatch

**Solution:**
1. Double-check SHA-1 is added to Firebase
2. Download fresh `google-services.json`
3. Wait 2-3 minutes after adding SHA-1 (Firebase needs time to propagate)
4. Rebuild app

---

### **Issue 2: Works in Debug, Fails in Release**

**Cause:** Different keystores have different SHA-1 fingerprints

**Solution:**
- Debug uses: `C:\Users\YourName\.android\debug.keystore`
- Release uses: `C:\Users\YourName\upload-keystore.jks`
- Add BOTH SHA-1 fingerprints to Firebase Console

---

### **Issue 3: "DEVELOPER_ERROR"**

**Causes:**
1. Wrong SHA-1 in Firebase
2. Wrong package name
3. Missing OAuth client configuration

**Solution:**
1. Verify package name matches: `com.drivemate.mds`
2. Check SHA-1 fingerprint is correct
3. Ensure `google-services.json` is in `android/app/` folder
4. Check Google Cloud Console has correct OAuth settings

---

### **Issue 4: "Network error" or "Unable to connect"**

**Causes:**
1. Internet connection issue
2. Firebase not initialized properly
3. Missing internet permission

**Solution:**
1. Check device internet connection
2. Verify `AndroidManifest.xml` has:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   ```
3. Ensure Firebase is initialized in `main.dart`

---

### **Issue 5: Google Sign-In Works on Emulator but Not Real Device**

**Cause:** Google Play Services outdated on device

**Solution:**
1. Update Google Play Services on device
2. Or test on a different device/emulator

---

## 🔧 Verification Checklist

Before testing, verify:

- [ ] Firebase Console has correct SHA-1: `19:76:BD:7D:98:26:62:A0:46:86:0C:13:44:21:00:E6:96:4D:9D:D6`
- [ ] Fresh `google-services.json` downloaded and replaced
- [ ] Package name is `com.drivemate.mds` everywhere
- [ ] App rebuilt after updating `google-services.json`
- [ ] Waiting 2-3 minutes after adding SHA-1 to Firebase
- [ ] Using release-signed APK (not debug)
- [ ] Internet connection working
- [ ] Google Play Services updated on device

---

## 📊 How Google Sign-In Works

```
User taps "Sign in with Google"
    ↓
App requests authentication from Firebase
    ↓
Firebase checks if app is authorized (via SHA-1)
    ↓
Firebase shows Google account picker
    ↓
User selects account
    ↓
Google verifies credentials
    ↓
Firebase receives authentication token
    ↓
Firebase creates/authenticates user in your app
```

**SHA-1 is critical** because it proves your app is who it claims to be!

---

## 🎯 Quick Fix Summary

### **If You Just Added Release SHA-1:**

1. ✅ Download fresh `google-services.json` from Firebase
2. ✅ Replace old file in `android/app/`
3. ✅ Run: `flutter clean && flutter pub get`
4. ✅ Run: `flutter build apk --release`
5. ✅ Install and test

### **If Still Not Working:**

1. Remove ALL SHA-1 from Firebase Console
2. Wait 5 minutes
3. Re-add all SHA-1 fingerprints (debug + release)
4. Download fresh `google-services.json`
5. Clean rebuild everything
6. Test again

---

## 📞 Need More Help?

### **Check Error Logs:**

Run app in debug mode to see detailed errors:
```bash
flutter run --release
```

Look for error messages like:
- `PlatformException(SIGN_IN_FAILED, ...)`
- `FirebaseAuthException`
- `DeveloperError`

### **Useful Commands:**

```bash
# Get debug SHA-1
keytool -list -v -keystore C:\Users\3muha\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android

# Get release SHA-1
keytool -list -v -keystore C:\Users\3muha\upload-keystore.jks -alias upload -storepass 8606642683

# Install release APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Uninstall app
adb uninstall com.drivemate.mds

# View logs
adb logcat | grep -i firebase
```

---

## ✅ Success Indicators

You'll know it's working when:
- ✅ Google account picker appears
- ✅ No error messages during sign-in
- ✅ User is authenticated in Firebase
- ✅ User data is saved to Firestore
- ✅ Can access protected app features

---

## 📝 Reference Information

### **Your Configuration:**

| Setting | Value |
|---------|-------|
| **Package Name** | `com.drivemate.mds` |
| **Firebase Project** | `smds-c1713` |
| **Release SHA-1** | `19:76:BD:7D:98:26:62:A0:46:86:0C:13:44:21:00:E6:96:4D:9D:D6` |
| **Keystore Password** | `8606642683` |
| **Key Alias** | `upload` |

### **File Locations:**

- `google-services.json`: `d:\mds\mds\android\app\google-services.json`
- `Keystore`: `C:\Users\3muha\upload-keystore.jks`
- `Release APK`: `build\app\outputs\flutter-apk\app-release.apk`

---

## 🎉 Final Notes

- **Multiple SHA-1 is normal** - you can have debug + release + Play Store signing
- **Wait for propagation** - Firebase changes take 2-5 minutes to take effect
- **Always use fresh google-services.json** after adding SHA-1
- **Test on real devices** - emulators sometimes behave differently

**Your fix:** Download fresh `google-services.json` from Firebase Console and rebuild! 🚀
