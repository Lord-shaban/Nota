# Social Authentication Setup Guide

This guide explains how to configure social authentication providers for the Nota app.

## Prerequisites

1. Firebase project already configured
2. Flutter development environment set up

---

## 1. Google Sign-In Setup

### Firebase Console:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project → Authentication → Sign-in method
3. Enable **Google** provider
4. Add your **Web client ID** (auto-generated)

### Android:
1. The `google-services.json` file is already in `android/app/`
2. SHA-1 fingerprint must be added in Firebase Console:
   ```bash
   # Get debug SHA-1
   keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android
   
   # For Windows
   keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -storepass android
   ```
3. Add the SHA-1 to Firebase Console → Project Settings → Your Apps → Android app

### iOS:
1. Download `GoogleService-Info.plist` and add to `ios/Runner/`
2. Add URL scheme in `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
           </array>
       </dict>
   </array>
   ```

---

## 2. Facebook Login Setup

### Facebook Developers:
1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create a new app or use existing
3. Add **Facebook Login** product
4. Get your **App ID** and **Client Token**

### Android:
1. Update `android/app/src/main/res/values/strings.xml`:
   ```xml
   <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
   <string name="facebook_client_token">YOUR_FACEBOOK_CLIENT_TOKEN</string>
   <string name="fb_login_protocol_scheme">fbYOUR_FACEBOOK_APP_ID</string>
   ```

2. Add Key Hashes to Facebook:
   ```bash
   # Get debug key hash
   keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64
   ```

### iOS:
Add to `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fbYOUR_FACEBOOK_APP_ID</string>
        </array>
    </dict>
</array>
<key>FacebookAppID</key>
<string>YOUR_FACEBOOK_APP_ID</string>
<key>FacebookClientToken</key>
<string>YOUR_FACEBOOK_CLIENT_TOKEN</string>
<key>FacebookDisplayName</key>
<string>Nota</string>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>fbapi</string>
    <string>fb-messenger-share-api</string>
</array>
```

### Firebase Console:
1. Authentication → Sign-in method → Enable **Facebook**
2. Enter your **App ID** and **App Secret**

---

## 3. GitHub Login Setup

### GitHub OAuth:
1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Create new OAuth App
3. Set callback URL: `https://YOUR_PROJECT.firebaseapp.com/__/auth/handler`

### Firebase Console:
1. Authentication → Sign-in method → Enable **GitHub**
2. Enter your **Client ID** and **Client Secret**

---

## 4. Apple Sign-In Setup (iOS/macOS only)

### Apple Developer:
1. Go to [Apple Developer](https://developer.apple.com/)
2. Identifiers → App IDs → Your App
3. Enable **Sign in with Apple**

### Firebase Console:
1. Authentication → Sign-in method → Enable **Apple**
2. Add your **Service ID** and configure key

### iOS:
Add capability in Xcode:
1. Open `ios/Runner.xcworkspace`
2. Runner → Signing & Capabilities → + Capability → Sign in with Apple

---

## 5. Biometric Authentication

### Android:
Already configured in `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

### iOS:
Add to `ios/Runner/Info.plist`:
```xml
<key>NSFaceIDUsageDescription</key>
<string>We need Face ID to authenticate you securely</string>
```

---

## Testing

After configuration:

1. **Google**: Should work immediately on Android with correct SHA-1
2. **Facebook**: Requires test users or app review for public access
3. **GitHub**: Works immediately after OAuth app creation
4. **Apple**: Requires paid Apple Developer account
5. **Biometric**: Works on devices with fingerprint/face sensors

---

## Troubleshooting

### Google Sign-In not working:
- Verify SHA-1 fingerprint in Firebase
- Check `google-services.json` is updated
- Ensure Web Client ID is configured

### Facebook Login error:
- Verify App ID and Client Token
- Check key hashes are added
- Ensure app is not in development mode (or add test users)

### Biometric not available:
- Device must have fingerprint/face sensor
- User must have enrolled at least one biometric

---

## Files Modified

- `pubspec.yaml` - Added packages
- `lib/features/auth/services/social_auth_service.dart` - New service
- `lib/features/auth/login/enhanced_login_screen.dart` - Updated UI
- `android/app/src/main/AndroidManifest.xml` - Android configuration
- `android/app/src/main/res/values/strings.xml` - Facebook strings

---

**Created by:** Team Nota
**Last Updated:** January 2026
