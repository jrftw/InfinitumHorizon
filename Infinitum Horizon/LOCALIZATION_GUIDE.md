# Infinitum Horizon - Localization Guide

## Overview

This guide provides comprehensive information about the localization implementation for Infinitum Horizon, covering the top 10 languages with complete translations for all user-facing text in the application.

## Supported Languages

The app supports the following 10 languages:

1. **English (en)** - Base language
2. **Spanish (es)** - Español
3. **French (fr)** - Français
4. **German (de)** - Deutsch
5. **Chinese Simplified (zh-Hans)** - 简体中文
6. **Japanese (ja)** - 日本語
7. **Italian (it)** - Italiano
8. **Portuguese (pt)** - Português
9. **Russian (ru)** - Русский
10. **Korean (ko)** - 한국어

## File Structure

```
Infinitum Horizon/
├── en.lproj/
│   └── Localizable.strings
├── es.lproj/
│   └── Localizable.strings
├── fr.lproj/
│   └── Localizable.strings
├── de.lproj/
│   └── Localizable.strings
├── zh-Hans.lproj/
│   └── Localizable.strings
├── ja.lproj/
│   └── Localizable.strings
├── it.lproj/
│   └── Localizable.strings
├── pt.lproj/
│   └── Localizable.strings
├── ru.lproj/
│   └── Localizable.strings
└── ko.lproj/
    └── Localizable.strings
```

## Localization Categories

The localization strings are organized into the following categories:

### 1. App Information
- App name, subtitle, version, build, about

### 2. Navigation
- Home, screens, connect, settings, account

### 3. Authentication
- Sign in/up, email, password, username, error messages

### 4. Content Management
- Items, add/select items, descriptions

### 5. Premium Features
- Upgrade prompts, pricing, terms, promo codes

### 6. Device Connectivity
- Multipeer connectivity, device status, messaging

### 7. Platform Specific
- iOS, macOS, tvOS, watchOS, visionOS specific text

### 8. Settings
- Appearance, features, quick actions

### 9. Screens
- Free/premium screens, screen numbers

### 10. System Messages
- Initialization, fallback mode, app status

### 11. User Interface
- Common UI elements (OK, Cancel, Save, etc.)

### 12. Time and Date
- Today, yesterday, time ago formats

### 13. Battery and System
- Battery status, charging indicators

### 14. Messages and Alerts
- Alert types, confirmations

### 15. Validation Messages
- Form validation, error messages

### 16. Network and Connectivity
- Connection status, network errors

### 17. Data Management
- Save, load, sync operations

### 18. Permissions
- Camera, photo, location, notification access

### 19. Store and Purchases
- Purchase flow, restore, pricing

### 20. Accessibility
- VoiceOver labels, accessibility descriptions

## Implementation Guide

### 1. Using Localized Strings in SwiftUI

Replace hardcoded strings with localized versions:

```swift
// Before
Text("Sign In")

// After
Text("auth_sign_in")
```

### 2. String Formatting

For strings with parameters, use the appropriate format specifiers:

```swift
// Date formatting
Text("content_item_at", item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))

// Number formatting
Text("screens_unlocked", user.unlockedScreens, user.totalScreens)

// Percentage formatting
Text("battery_percentage", Int(batteryLevel * 100))
```

### 3. Pluralization

For plural forms, use the appropriate string keys:

```swift
// English: "5 minutes ago"
Text("time_minutes_ago", 5)

// Spanish: "hace 5 minutos"
Text("time_minutes_ago", 5)
```

### 4. Dynamic Language Switching

To implement dynamic language switching:

```swift
import SwiftUI

class LocalizationManager: ObservableObject {
    @Published var currentLanguage: String = "en"
    
    func setLanguage(_ languageCode: String) {
        currentLanguage = languageCode
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
}
```

### 5. Xcode Project Configuration

1. Add all `.lproj` folders to your Xcode project
2. Ensure "Localizable.strings" is included in the target
3. Set the development language to English
4. Add supported languages in Project Settings > Info > Localizations

## String Key Naming Convention

All string keys follow a consistent naming pattern:

- **Category prefix**: `auth_`, `premium_`, `ui_`, etc.
- **Descriptive name**: `sign_in`, `upgrade_description`, `ok`
- **Lowercase with underscores**: `auth_sign_in`, `premium_upgrade`

## Best Practices

### 1. Context-Aware Translations
- Provide context comments for translators
- Use descriptive key names
- Group related strings together

### 2. String Length Considerations
- Some languages (like German) produce longer text
- Design UI with flexible layouts
- Test with longest possible translations

### 3. Cultural Adaptations
- Consider cultural differences in date/time formats
- Adapt currency and number formatting
- Respect local UI conventions

### 4. Testing
- Test with all supported languages
- Verify string truncation doesn't occur
- Check right-to-left language support (if needed)

## Adding New Languages

To add a new language:

1. Create a new `.lproj` folder with the language code
2. Copy the English `Localizable.strings` file
3. Translate all strings to the target language
4. Add the language to Xcode project settings
5. Test thoroughly with native speakers

## Quality Assurance

### Translation Review Process
1. **Initial Translation**: Professional translation service
2. **Technical Review**: Verify string formatting and placeholders
3. **Context Review**: Ensure translations fit the UI context
4. **User Testing**: Test with native speakers
5. **Final Review**: Approve for production

### Common Issues to Check
- Missing string keys
- Incorrect format specifiers
- Truncated text in UI
- Inconsistent terminology
- Cultural appropriateness

## Maintenance

### Regular Updates
- Review and update translations quarterly
- Add new strings as features are developed
- Remove obsolete strings
- Update terminology consistency

### Version Control
- Track changes to localization files
- Document translation updates
- Maintain translation memory for consistency

## Resources

### Translation Tools
- Xcode's built-in localization tools
- Professional translation services
- Translation memory systems
- Automated quality checks

### Testing Tools
- iOS Simulator language switching
- Device testing with different locales
- Automated UI testing with multiple languages

## Support

For questions about localization implementation:
1. Check this guide first
2. Review the string keys in the localization files
3. Test with the iOS Simulator
4. Consult with native speakers for accuracy

---

*This localization guide is maintained as part of the Infinitum Horizon project. Last updated: January 2025* 