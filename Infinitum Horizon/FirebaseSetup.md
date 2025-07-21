# Firebase Setup Guide for Infinitum Horizon

This guide will help you set up Firebase integration for the Infinitum Horizon project.

## Prerequisites

- Xcode 16.0 or later
- iOS 17.0+ / macOS 14.0+ / tvOS 17.0+ / watchOS 10.0+ / visionOS 1.0+
- Firebase account
- Apple Developer account (for push notifications)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `infinitum-horizon`
4. Enable Google Analytics (recommended)
5. Choose Analytics account or create new one
6. Click "Create project"

## Step 2: Configure iOS App

1. In Firebase Console, click the iOS icon (+ Add app)
2. Enter iOS bundle ID: `com.infinitumhorizon.app`
3. Enter app nickname: `Infinitum Horizon`
4. Click "Register app"
5. Download `GoogleService-Info.plist`
6. Add the file to your Xcode project:
   - Drag `GoogleService-Info.plist` into your Xcode project
   - Make sure "Copy items if needed" is checked
   - Add to all targets (iOS, macOS, tvOS, watchOS, visionOS)

## Step 2.5: Add Firebase Dependencies in Xcode

1. **Open your Xcode project**
2. **Select your project** in the navigator
3. **Select your target** (Infinitum Horizon)
4. **Go to "Package Dependencies" tab**
5. **Click the "+" button** to add a package
6. **Enter Firebase URL**: `https://github.com/firebase/firebase-ios-sdk.git`
7. **Click "Add Package"**
8. **Select the following products**:
   - `FirebaseAuth`
   - `FirebaseFirestore`
   - `FirebaseFirestoreSwift`
   - `FirebaseStorage`
   - `FirebaseAnalytics`
   - `FirebaseCrashlytics`
   - `FirebaseMessaging`
   - `FirebaseRemoteConfig`
9. **Add to all targets** (iOS, macOS, tvOS, watchOS, visionOS)

### Optional: Google Sign-In
1. **Add another package**: `https://github.com/google/GoogleSignIn-iOS.git`
2. **Select products**:
   - `GoogleSignIn`
   - `GoogleSignInSwift`

## Step 3: Configure Additional Platforms

### macOS
1. In Firebase Console, click "Add app" → macOS
2. Bundle ID: `com.infinitumhorizon.app`
3. Download and add `GoogleService-Info.plist` to macOS target

### tvOS
1. In Firebase Console, click "Add app" → tvOS
2. Bundle ID: `com.infinitumhorizon.app`
3. Download and add `GoogleService-Info.plist` to tvOS target

### watchOS
1. In Firebase Console, click "Add app" → watchOS
2. Bundle ID: `com.infinitumhorizon.app`
3. Download and add `GoogleService-Info.plist` to watchOS target

### visionOS
1. In Firebase Console, click "Add app" → iOS (visionOS uses iOS bundle)
2. Bundle ID: `com.infinitumhorizon.app`
3. Download and add `GoogleService-Info.plist` to visionOS target

## Step 4: Enable Firebase Services

### Authentication
1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Enable Email/Password authentication
4. Enable Anonymous authentication
5. (Optional) Enable Google Sign-In
6. (Optional) Enable Apple Sign-In

### Firestore Database
1. Go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select location closest to your users
5. Click "Done"

### Storage
1. Go to "Storage"
2. Click "Get started"
3. Choose "Start in test mode" (for development)
4. Select location closest to your users
5. Click "Done"

### Analytics
1. Go to "Analytics"
2. Analytics is automatically enabled when you create the project

### Crashlytics
1. Go to "Crashlytics"
2. Click "Get started"
3. Follow the setup instructions

### Remote Config
1. Go to "Remote Config"
2. Click "Get started"
3. Create your first parameter (optional)

## Step 5: Configure Security Rules

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Users can access their own sessions
      match /sessions/{sessionId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Public sessions (if needed)
    match /public_sessions/{sessionId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### Storage Security Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can only upload their own avatars
    match /avatars/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Session assets
    match /sessions/{sessionId}/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Step 6: Configure Push Notifications (Optional)

1. In Firebase Console, go to "Project settings"
2. Go to "Cloud Messaging" tab
3. Upload your APNs authentication key:
   - Download from Apple Developer Console
   - Upload to Firebase Console
4. Copy the Server Key for server-side notifications

## Step 7: Environment Configuration

### Development vs Production
Create different Firebase projects for development and production:

- `infinitum-horizon-dev` (Development)
- `infinitum-horizon-prod` (Production)

### Environment Variables
Add these to your Xcode project:

```
FIREBASE_ENVIRONMENT=development
FIREBASE_ANALYTICS_ENABLED=true
FIREBASE_CRASHLYTICS_ENABLED=true
```

## Step 8: Testing Firebase Integration

1. Build and run the app
2. Check Xcode console for Firebase initialization messages
3. Test authentication flow
4. Test data synchronization
5. Check Firebase Console for analytics events

## Step 9: Production Deployment

### Before Release
1. Update Firestore security rules for production
2. Update Storage security rules for production
3. Configure proper authentication methods
4. Set up proper error monitoring
5. Test all Firebase features thoroughly

### App Store Submission
1. Ensure all Firebase configurations are production-ready
2. Test with production Firebase project
3. Verify analytics and crash reporting work
4. Check that all Firebase services are properly configured

## Troubleshooting

### Common Issues

1. **Firebase not initializing**
   - Check `GoogleService-Info.plist` is added to all targets
   - Verify bundle ID matches Firebase configuration
   - Check network connectivity

2. **Authentication errors**
   - Verify authentication methods are enabled in Firebase Console
   - Check email/password authentication is enabled
   - Verify anonymous authentication is enabled

3. **Firestore permission errors**
   - Check security rules
   - Verify user is authenticated
   - Check document paths match security rules

4. **Storage upload failures**
   - Check storage security rules
   - Verify file size limits
   - Check network connectivity

### Debug Mode
Enable Firebase debug mode in development:

```swift
#if DEBUG
FirebaseConfiguration.shared.setLoggerLevel(.debug)
#endif
```

## Security Best Practices

1. **Never commit API keys to version control**
   - Use environment variables
   - Use different projects for dev/prod
   - Rotate keys regularly

2. **Implement proper security rules**
   - Always validate user authentication
   - Use least privilege principle
   - Test security rules thoroughly

3. **Monitor usage and costs**
   - Set up billing alerts
   - Monitor API usage
   - Review costs regularly

4. **Regular security audits**
   - Review security rules
   - Check for unused services
   - Update dependencies regularly

## Support

For Firebase-specific issues:
- [Firebase Documentation](https://firebase.google.com/docs)
- [Firebase Support](https://firebase.google.com/support)
- [Firebase Community](https://firebase.google.com/community)

For Infinitum Horizon specific issues:
- Check the project documentation
- Review the code comments
- Contact the development team 