# Apple Sign-In & Google Sign-In Configuration Guide

This document provides setup instructions for Apple Sign-In and Google Sign-In integration in the MigozzApp.

## ✅ Completed Implementation

### Code Changes

1. **Dependencies Added**
   - `sign_in_with_apple: ^7.0.1` - Apple Sign-In package

2. **Authentication Layer**
   - ✅ Added `loginWithApple()` method to `AuthRepository` interface
   - ✅ Implemented Apple Sign-In in `AuthService` with Firebase integration
   - ✅ Created `LoginAppleUseCase` for business logic
   - ✅ Updated `AuthRepositoryImpl` to support Apple Sign-In
   - ✅ Updated `AuthUseCases` to include `loginApple`
   - ✅ Added `signInWithApple()` method to `AuthCubit`

3. **UI Components**
   - ✅ Created `apple_button.dart` component
   - ✅ Updated mobile login screen with Apple Sign-In button
   - ✅ Updated web login form with Apple Sign-In button
   - ✅ Both Google and Apple buttons displayed side-by-side

4. **iOS Configuration**
   - ✅ Created `ios/Runner/Runner.entitlements` with Apple Sign-In capability
   - ✅ Added Google Sign-In URL scheme to `Info.plist`
   - ✅ Configured `CFBundleURLTypes` for OAuth redirects

## 🔧 Required Setup Steps

### 1. Apple Sign-In Configuration

#### A. Apple Developer Console Setup

1. **Enable Sign in with Apple Capability**
   - Go to [Apple Developer Console](https://developer.apple.com)
   - Navigate to Certificates, Identifiers & Profiles
   - Select your App ID (`com.migozz.app`)
   - Enable "Sign in with Apple" capability
   - Click "Edit" and configure as needed
   - Save changes

2. **Create Service ID (for Web)**
   - In Identifiers, create a new Service ID
   - Use identifier like `com.migozz.app.signin`
   - Enable "Sign in with Apple"
   - Configure domains and redirect URLs:
     - Domains: `migozz.com`, `api.migozz.com`
     - Return URLs: `https://migozz-e2a21.firebaseapp.com/__/auth/handler`

3. **Create Key for Apple Sign-In**
   - Go to Keys section
   - Create a new key
   - Enable "Sign in with Apple"
   - Download the key file (you can only download once!)
   - Note the Key ID

#### B. Firebase Console Setup

1. **Enable Apple Sign-In Provider**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Select your project: `migozz-e2a21`
   - Navigate to Authentication > Sign-in method
   - Enable "Apple" provider
   - Upload the key file from Apple Developer
   - Enter Service ID, Team ID, and Key ID
   - Save configuration

#### C. Xcode Project Configuration

1. **Open Xcode Project**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Add Sign in with Apple Capability**
   - Select the Runner target
   - Go to "Signing & Capabilities" tab
   - Click "+ Capability"
   - Add "Sign in with Apple"
   - Ensure the entitlements file is linked

3. **Link Entitlements File**
   - In Build Settings, search for "Code Signing Entitlements"
   - Set value to: `Runner/Runner.entitlements`

4. **Verify Bundle Identifier**
   - Ensure Bundle Identifier matches: `com.migozz.app`

### 2. Google Sign-In Configuration

#### A. Google Cloud Console Setup

1. **Configure OAuth Consent Screen**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Select your project
   - Navigate to APIs & Services > OAuth consent screen
   - Configure app information and scopes

2. **Create iOS OAuth Client**
   - Go to APIs & Services > Credentials
   - Create OAuth 2.0 Client ID
   - Application type: iOS
   - Bundle ID: `com.migozz.app`
   - Note the Client ID

3. **Verify Existing Credentials**
   - iOS Client ID: `895592952324-9com24km36qtr9pcpv6752qkgmf4otn3.apps.googleusercontent.com`
   - Android Client ID: `895592952324-acochpgr4ch4o97669jjpafeosgv7khg.apps.googleusercontent.com`
   - These are already configured in `GoogleService-Info.plist`

#### B. Firebase Console Setup

1. **Enable Google Sign-In Provider**
   - Go to Firebase Console
   - Navigate to Authentication > Sign-in method
   - Enable "Google" provider
   - Configure support email
   - Save configuration

#### C. iOS Configuration (Already Done)

✅ The following are already configured:
- `GoogleService-Info.plist` is present with correct credentials
- `CFBundleURLTypes` added to `Info.plist` with REVERSED_CLIENT_ID
- URL Scheme: `com.googleusercontent.apps.895592952324-9com24km36qtr9pcpv6752qkgmf4otn3`

### 3. Environment Variables

Verify `.env` file contains (if needed for web):
```
GOOGLE_CLIENT_ID=<your-web-client-id>
```

**Note**: For iOS, the client ID is read from `GoogleService-Info.plist`, not from `.env`.

## 🧪 Testing

### Test Apple Sign-In

1. **iOS Device/Simulator Requirements**
   - iOS 13.0 or later
   - Signed in with Apple ID in Settings
   - For simulator: Use a test Apple ID

2. **Test Flow**
   ```bash
   flutter run -d <ios-device>
   ```
   - Tap "Apple" button on login screen
   - Complete Apple Sign-In flow
   - Verify user is created in Firebase Authentication
   - Verify user document is created in Firestore

### Test Google Sign-In

1. **iOS Device/Simulator**
   ```bash
   flutter run -d <ios-device>
   ```
   - Tap "Google" button on login screen
   - Select Google account
   - Verify authentication succeeds
   - Check Firebase console for user

2. **Web Browser**
   ```bash
   flutter run -d chrome
   ```
   - Test Google Sign-In on web
   - Verify OAuth flow completes

## 📱 Platform Support

| Feature | iOS | Android | Web |
|---------|-----|---------|-----|
| Apple Sign-In | ✅ | ⚠️ Limited | ✅ |
| Google Sign-In | ✅ | ✅ | ✅ |

**Note**: Apple Sign-In on Android requires additional setup and has limitations.

## 🔍 Troubleshooting

### Apple Sign-In Issues

1. **"Invalid client" error**
   - Verify Service ID is correctly configured in Apple Developer
   - Check Firebase Apple provider configuration
   - Ensure redirect URLs match exactly

2. **Entitlements not found**
   - Verify `Runner.entitlements` is linked in Xcode
   - Clean build folder: `flutter clean && flutter pub get`
   - Rebuild iOS project

3. **User cancellation**
   - This is normal behavior when user cancels
   - Error is caught and not shown to user

### Google Sign-In Issues

1. **"DEVELOPER_ERROR" on iOS**
   - Verify `CFBundleURLTypes` in `Info.plist`
   - Check REVERSED_CLIENT_ID matches `GoogleService-Info.plist`
   - Ensure Bundle ID matches Google Cloud Console

2. **"Sign in failed" error**
   - Check internet connection
   - Verify OAuth client is enabled in Google Cloud Console
   - Check Firebase project configuration

3. **Web client ID issues**
   - For iOS native, client ID comes from `GoogleService-Info.plist`
   - For web, ensure correct web client ID in `.env`

## 📝 Files Modified

### New Files
- `lib/features/auth/components/apple_button.dart`
- `lib/features/auth/data/domain/use_cases/login_apple_use_case.dart`
- `ios/Runner/Runner.entitlements`

### Modified Files
- `pubspec.yaml` - Added sign_in_with_apple dependency
- `lib/features/auth/data/domain/repository/auth_repository.dart`
- `lib/features/auth/data/datasources/auth_service.dart`
- `lib/features/auth/data/repository/auth_repository_impl.dart`
- `lib/features/auth/data/domain/use_cases/auth_use_cases.dart`
- `lib/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart`
- `lib/features/auth/presentation/login/mobile/login_screen.dart`
- `lib/features/auth/presentation/login/web/login_form.dart`
- `lib/core/di/app_module.dart`
- `ios/Runner/Info.plist` - Added CFBundleURLTypes for Google Sign-In

## 🚀 Next Steps

1. Complete Apple Developer Console setup
2. Configure Firebase Apple Sign-In provider
3. Link entitlements in Xcode
4. Test on physical iOS device
5. Test on web browser
6. Deploy to TestFlight for beta testing

## 📚 References

- [Apple Sign-In Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Firebase Apple Sign-In Guide](https://firebase.google.com/docs/auth/ios/apple)
- [Google Sign-In for iOS](https://developers.google.com/identity/sign-in/ios)
- [sign_in_with_apple Package](https://pub.dev/packages/sign_in_with_apple)
- [google_sign_in Package](https://pub.dev/packages/google_sign_in)

