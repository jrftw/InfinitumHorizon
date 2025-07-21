# Cross-Device Control

## Overview

Cross-Device Control is a **Premium Feature** that allows you to control your Apple devices from your Vision Pro. This feature enables seamless interaction between your devices, allowing you to launch apps, open URLs, send haptic feedback, and execute commands across your Apple ecosystem.

## Premium Requirement

⚠️ **Cross-Device Control requires a Premium subscription**

- **Free Users**: Will see a premium upgrade prompt when accessing this feature
- **Premium Users**: Have full access to all cross-device control capabilities

## Supported Devices

### Control Hub (Vision Pro)
- **Role**: Primary control device
- **Actions**: Browse for nearby devices, send commands, control other devices
- **Requirements**: visionOS 1.0+, Premium subscription, same Wi-Fi network

### Target Devices

#### iPhone/iPad
- **Control Actions**: Launch apps, open URLs, send messages
- **Requirements**: iOS 15.0+, Infinitum Horizon app, Premium subscription
- **Setup**: Install app → Open → Start Hosting → Grant permissions

#### Mac
- **Control Actions**: Run scripts, open apps, execute commands
- **Requirements**: macOS 12.0+, Infinitum Horizon app, Premium subscription
- **Setup**: Install app → Open → Start Hosting → Enable Local Network permissions

#### Apple Watch
- **Control Actions**: Send haptics, start workouts, notifications
- **Requirements**: watchOS 8.0+, Infinitum Horizon app, Premium subscription
- **Setup**: Install app → Open → Start Hosting → Keep app in foreground

#### Apple TV
- **Control Actions**: Launch apps, control playback
- **Requirements**: tvOS 15.0+, Infinitum Horizon app, Premium subscription
- **Setup**: Install app → Open → Start Hosting → Keep app active

## How to Use

### Step 1: Upgrade to Premium
1. Open Infinitum Horizon on your Vision Pro
2. Navigate to Cross-Device Control
3. Tap "Upgrade to Premium" if you haven't already
4. Choose your subscription plan (Monthly or Yearly)

### Step 2: Setup Target Devices

#### For iPhone/iPad:
1. **Install App**: Download Infinitum Horizon from the App Store
2. **Open App**: Launch the app and navigate to Cross-Device Control
3. **Start Hosting**: Tap "Start Hosting" to make your device discoverable
4. **Grant Permissions**: Allow notifications and local network access when prompted
5. **Wait for Connection**: Your device will appear in the Vision Pro's device list

#### For Mac:
1. **Install App**: Download Infinitum Horizon from the Mac App Store
2. **Open App**: Launch the app and go to Cross-Device Control
3. **Start Hosting**: Click "Start Hosting" to make your Mac discoverable
4. **System Preferences**: Go to System Preferences > Security & Privacy > Privacy > Local Network
5. **Enable Local Network**: Check the box next to Infinitum Horizon
6. **Wait for Connection**: Your Mac will appear in the Vision Pro's device list

#### For Apple Watch:
1. **Install App**: Install Infinitum Horizon on your Apple Watch from the Watch app
2. **Open App**: Launch the app on your Apple Watch
3. **Start Hosting**: Tap "Start Hosting" to make your watch discoverable
4. **Keep App Open**: Keep the app running in the foreground
5. **Wait for Connection**: Your watch will appear in the Vision Pro's device list

#### For Apple TV:
1. **Install App**: Download Infinitum Horizon from the App Store on Apple TV
2. **Open App**: Launch the app using the Siri Remote
3. **Start Hosting**: Select "Start Hosting" to make your Apple TV discoverable
4. **Keep App Active**: Keep the app running (don't go to home screen)
5. **Wait for Connection**: Your Apple TV will appear in the Vision Pro's device list

### Step 3: Control from Vision Pro

1. **Open App**: Launch Infinitum Horizon on your Vision Pro
2. **Navigate to Control**: Go to Cross-Device Control section
3. **Start Browsing**: Tap "Start Browsing" to discover nearby devices
4. **Select Device**: Tap on a device in the list to connect
5. **Grant Permissions**: Allow the connection when prompted
6. **Start Controlling**: Use the quick actions to control your device

## Quick Actions Available

### Universal Actions
- **Open URL**: Launch any URL on the target device
- **Launch App**: Start any installed app
- **Send Message**: Send text messages between devices

### Device-Specific Actions

#### iPhone/iPad
- Launch apps
- Open URLs
- Send notifications
- Control media playback

#### Mac
- Run AppleScript commands
- Launch applications
- Execute terminal commands
- Control system settings

#### Apple Watch
- Send haptic feedback
- Start/stop workouts
- Send notifications
- Control watch faces

#### Vision Pro
- Change layout modes
- Control immersive experiences
- Adjust spatial settings
- Manage windows

#### Apple TV
- Launch apps
- Control media playback
- Navigate menus
- Adjust settings

## Troubleshooting

### Common Issues

#### Devices Not Appearing
- **Check Network**: Ensure all devices are on the same Wi-Fi network
- **Verify Hosting**: Make sure target devices are actively hosting
- **Restart Apps**: Close and reopen the app on both devices
- **Check Permissions**: Verify local network permissions are granted

#### Connection Failures
- **Bluetooth**: Ensure Bluetooth is enabled on all devices
- **Distance**: Move devices closer together
- **Firewall**: Check firewall settings on Mac
- **VPN**: Try disabling VPN if active

#### Permission Issues
- **iOS/iPadOS**: Settings > Privacy & Security > Local Network
- **macOS**: System Preferences > Security & Privacy > Privacy > Local Network
- **visionOS**: Settings > Privacy & Security > Local Network

### Device-Specific Troubleshooting

#### iPhone/iPad
- Make sure both devices are on the same Wi-Fi network
- Check that Bluetooth is enabled on both devices
- Restart the app if connection fails
- Ensure the app has notification permissions
- Try moving devices closer together

#### Mac
- Check System Preferences > Security & Privacy > Privacy > Local Network
- Ensure both devices are on the same Wi-Fi network
- Restart the app if connection fails
- Check firewall settings
- Try disabling VPN if active

#### Apple Watch
- Keep the app running in the foreground
- Ensure your iPhone is on the same network
- Check that the watch is unlocked
- Restart the app if connection fails
- Try restarting both watch and iPhone

#### Vision Pro
- Make sure you're browsing for devices
- Check that target devices are hosting
- Ensure all devices are on the same network
- Try refreshing the device list
- Restart the app if no devices appear

#### Apple TV
- Keep the app active (don't go to home screen)
- Ensure both devices are on the same network
- Check that the Apple TV is not in sleep mode
- Restart the app if connection fails
- Try restarting the Apple TV

## Security & Privacy

### Data Protection
- All communications are encrypted end-to-end
- No data is stored on external servers
- Local network communication only
- Automatic connection timeout for security

### Permissions Required
- **Local Network**: For device discovery and communication
- **Notifications**: For command delivery and status updates
- **Bluetooth**: For proximity detection and enhanced connectivity

## Technical Details

### Network Requirements
- **Protocol**: MultipeerConnectivity framework
- **Encryption**: Required encryption for all communications
- **Service Type**: `infinitum-ctrl` (13 characters, compliant with Apple guidelines)
- **Discovery**: Bonjour-based local network discovery

### Performance
- **Latency**: < 100ms for most commands
- **Range**: Up to 50 meters in open space
- **Bandwidth**: Minimal data usage
- **Battery**: Optimized for minimal battery impact

## Support

### Getting Help
1. **Check Requirements**: Verify all devices meet minimum requirements
2. **Follow Setup**: Use the detailed setup instructions for each device type
3. **Troubleshoot**: Try the troubleshooting steps above
4. **Contact Support**: If issues persist, contact our support team

### Premium Support
- **Priority Support**: Premium users get priority support
- **Extended Hours**: Support available during extended hours
- **Direct Contact**: Direct access to technical support team

---

**Note**: Cross-Device Control is a premium feature that requires an active subscription. Free users will be prompted to upgrade when attempting to access this functionality. 