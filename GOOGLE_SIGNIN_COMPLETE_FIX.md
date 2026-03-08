# 🔐 Google Sign-In Complete Fix Checklist

## ⚠️ CRITICAL: You MUST complete ALL steps

---

## ✅ Step 1: Get SHA-1 Fingerprints

### 1A. Debug SHA-1 (for development)
```bash
keytool -list -v -keystore C:\Users\3muha\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Debug SHA-1:** `________________________________________`

---

### 1B. Upload Certificate SHA-1 (your keystore)
```bash
keytool -list -v -keystore C:\Users\3muha\upload-keystore.jks -alias upload -storepass 8606642683
```

**Upload SHA-1:** `19:76:BD:7D:98:26:62:A0:46:86:0C:13:44:21:00:E6:96:4D:9D:D6`

---

### 1C. Google Play App Signing SHA-1 (MOST IMPORTANT!)
**Get this from Google Play Console:**

1. Go to: https://play.google.com/console/u/0/
2. Select "Drivemate" app
3. Click "Setup" → "App integrity"
4. Find "App signing key certificate"
5. Copy SHA-1 fingerprint

**Google Play SHA-1:** `________________________________________`

---

## ✅ Step 2: Add ALL SHA-1 to Firebase Console

1. Go to: https://console.firebase.google.com/project/smds-c1713/settings/general
2. Scroll to "Your apps" section
3. Find Android app: `com.drivemate.mds`
4. Click "Add fingerprint" button
5. Add **ALL THREE** SHA-1 fingerprints:
   - ✅ Debug SHA-1
   - ✅ Upload Certificate SHA-1
   - ✅ Google Play App Signing SHA-1

**⚠️ WAIT 2-3 MINUTES** after adding fingerprints (Firebase needs time to propagate)

---

## ✅ Step 3: Download New google-services.json

1. In Firebase Console, click "Download google-services.json"
2. Save to: `d:\mds\mds\android\app\google-services.json`
3. Replace the old file

---

## ✅ Step 4: Verify Firebase Authentication Settings

1. Go to: https://console.firebase.google.com/project/smds-c1713/authentication/providers
2. Enable "Google" sign-in provider
3. Make sure these OAuth redirects are configured:
   - ✅ `com.drivemate.mds` is listed
   - ✅ SHA-1 fingerprints match

---

## ✅ Step 5: Update Google Play Console (if needed)

If you changed package name to `com.drivemate.mds`:

1. Go to: https://play.google.com/console/u/0/
2. Select "Drivemate" app
3. Go to "Main store listing"
4. Verify package name matches: `com.drivemate.mds`

---

## ✅ Step 6: Clean Build and Test

### For Debug Testing:
```bash
flutter clean
flutter pub get
flutter run --release
```

### For Play Store Release:

1. **Build release bundle:**
   ```bash
   flutter build appbundle --release
   ```

2. **Upload to Play Console:**
   - Go to: https://play.google.com/console/u/0/
   - Select "Production" track
   - Create new release
   - Upload the .aab file
   - Wait for processing (5-10 minutes)

3. **Test on real device:**
   - Uninstall any existing version
   - Install from Play Store (internal testing track first)
   - Try Google Sign-In

---

## 🎯 Verification Checklist

Before testing, verify:

- [ ] All 3 SHA-1 fingerprints added to Firebase
- [ ] New google-services.json downloaded and replaced
- [ ] Package name matches: `com.drivemate.mds`
- [ ] Google Sign-In enabled in Firebase Authentication
- [ ] Waited 2-3 minutes after adding SHA-1
- [ ] Built and uploaded NEW release bundle to Play Store
- [ ] Installed from Play Store (not sideloaded)

---

## 🚨 Common Mistakes

❌ **Only adding debug SHA-1** → Need ALL three  
❌ **Not waiting for Firebase propagation** → Wait 2-3 minutes  
❌ **Testing with old APK** → Must install from Play Store  
❌ **Wrong package name** → Must be `com.drivemate.mds`  
❌ **Missing Google Play SHA-1** → This is the most common issue!  

---

## 📞 Still Not Working?

### Check Error Logs:

```bash
adb logcat | grep -i firebase
adb logcat | grep -i google
```

### Look for errors like:
- `DEVELOPER_ERROR` → SHA-1 mismatch or wrong package name
- `SIGN_IN_FAILED` → OAuth client not configured
- `NETWORK_ERROR` → Internet connection issue

### Quick Debug Commands:

```bash
# Verify google-services.json has correct package
cd android/app
cat google-services.json | findstr "package_name"

# Should show: "package_name": "com.drivemate.mds"
```

---

## ✅ Success Indicators

You'll know it's working when:

✅ Google account picker appears  
✅ No error messages during sign-in  
✅ User authenticated in Firebase  
✅ Firestore user document created/updated  
✅ Can access protected features  

---

## 📝 Reference Information

### Your Configuration:

| Setting | Value |
|---------|-------|
| **Package Name** | `com.drivemate.mds` |
| **Firebase Project** | `smds-c1713` |
| **Upload Keystore SHA-1** | `19:76:BD:7D:98:26:62:A0:46:86:0C:13:44:21:00:E6:96:4D:9D:D6` |
| **Keystore Password** | `8606642683` |
| **Key Alias** | `upload` |

---

## 🎯 Next Steps

1. ☑️ Get Google Play App Signing SHA-1 from Play Console
2. ☑️ Add all 3 SHA-1 to Firebase
3. ☑️ Download new google-services.json
4. ☑️ Build and upload new release to Play Store
5. ☑️ Test from Play Store installation

**Expected timeline:** 10-15 minutes total (including Firebase propagation)
