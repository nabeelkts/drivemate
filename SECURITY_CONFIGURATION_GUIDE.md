# Security Configuration Guide

## Firebase API Keys (Client-Side)

The Firebase API keys in `lib/firebase_options.dart` and `android/app/google-services.json` are **client-side keys** that are intentionally exposed. This is standard practice for Firebase mobile/web applications. The security comes from Firebase Console configuration.

### Recommended Firebase Console Restrictions

1. **Go to Firebase Console** → **Project Settings** → **API Keys**

2. **Restrict each API key:**
   - **Web API Key** (`AIzaSyCI8-HLaRDuj-5GcdI_xoYJJkZSusZBIAU`):
     - Accept requests from: Your domain only (e.g., `smds-c1713.web.app`)
     - HTTP referrers: `*.smds-c1713.web.app`, `localhost`
   
   - **Android API Key** (`AIzaSyDXiXhkXKfn3PnhapAYJAWemfjX8IUYG9g`):
     - Apps: Restrict to `com.drivemate.mds` and `com.example.mds`
     - Certificate fingerprints should match those in `google-services.json`
   
   - **iOS API Keys** (`AIzaSyC8-L5lNulEs3vwYa6N_FwToqxmwe7CU-M`):
     - Bundle identifiers: `com.drivemate.mds`, `com.example.mds`

3. **Disable unused Firebase services** in Firebase Console → Build → (disable any unused APIs)

## Current Security Measures

### Authentication
- ✅ Firebase Authentication handles all login/signup
- ✅ Email verification required before account activation
- ✅ Rate limiting on login attempts (5 attempts → 15 min lockout)
- ✅ Progressive lockout (lockout time doubles with repeated failures)
- ✅ Password reset rate limiting (3 attempts → 60 min lockout)

### Database Security (Firestore)
- ✅ Firestore Security Rules implemented in `firestore.rules`
- ✅ Role-based access control (Owner, Staff, Student)
- ✅ School-based data isolation
- ✅ Default deny-all rule
- ✅ Users can only access their own data

### Abuse Protection
- ✅ Account creation rate limiting (3 attempts/hour)
- ✅ Email-based registration limiting (2 registrations/email/24h)
- ✅ API endpoint rate limiting (60 req/min, 500 req/hour)
- ✅ AI/OCR request rate limiting
- ✅ Bot detection and suspicious activity tracking
- ✅ Data scraping protection

### Client-Side Security
- ✅ Passwords NEVER stored in local storage
- ✅ Only email stored for biometric login
- ✅ Session timeout (30 minutes)
- ✅ Biometric authentication support

## Environment Variables

This project uses Firebase which handles configuration via:
- `lib/firebase_options.dart` - Web, Android, iOS, macOS configs
- `android/app/google-services.json` - Android OAuth/API keys
- `ios/GoogleService-Info.plist` - iOS configuration

**No additional server-side secrets required** - Firebase handles authentication and API security.

## Recommendations

1. **Firebase Console**: Configure API key restrictions as described above
2. **Enable 2FA**: In Firebase Console → Authentication → User management
3. **Monitor**: Set up Firebase alerts for suspicious activity
4. **Regular audits**: Review Firebase Console logs monthly

## Files to NEVER Commit

These files contain sensitive configurations and should be in `.gitignore`:
- `android/app/*.jks` - Android keystores
- `android/key.properties` - Build keys
- `*.pem` / `*.p12` - Certificate files

The current `.gitignore` correctly excludes keystore files.
