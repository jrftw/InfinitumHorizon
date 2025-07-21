#!/bin/bash

echo "🧪 Testing visionOS Build (No Firebase)"
echo "======================================"

# Check if we're in the right directory
if [ ! -f "Infinitum Horizon.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Not in the Infinitum Horizon project directory"
    exit 1
fi

echo "✅ Project found"

# Check for visionOS-specific files
echo "🔍 Checking visionOS files..."

if [ -f "Infinitum Horizon/visionOS/VisionOSEntryView.swift" ]; then
    echo "✅ VisionOSEntryView.swift found"
else
    echo "❌ VisionOSEntryView.swift missing"
    exit 1
fi

if [ -f "Infinitum Horizon/Shared/Storage/VisionOSDataManager.swift" ]; then
    echo "✅ VisionOSDataManager.swift found"
else
    echo "❌ VisionOSDataManager.swift missing"
    exit 1
fi

# Check for Firebase imports in visionOS files
echo "🔍 Checking for Firebase imports in visionOS files..."

if grep -q "import Firebase" "Infinitum Horizon/visionOS/VisionOSEntryView.swift"; then
    echo "❌ Firebase import found in VisionOSEntryView.swift"
    exit 1
else
    echo "✅ No Firebase imports in VisionOSEntryView.swift"
fi

if grep -q "import Firebase" "Infinitum Horizon/Shared/Storage/VisionOSDataManager.swift"; then
    echo "❌ Firebase import found in VisionOSDataManager.swift"
    exit 1
else
    echo "✅ No Firebase imports in VisionOSDataManager.swift"
fi

# Check main app file for visionOS Firebase exclusion
if grep -q "#if !os(visionOS)" "Infinitum Horizon/Infinitum_HorizonApp.swift"; then
    echo "✅ Firebase excluded for visionOS in main app"
else
    echo "❌ Firebase not properly excluded for visionOS"
    exit 1
fi

echo ""
echo "🎉 All checks passed! visionOS build should work without Firebase."
echo ""
echo "📱 To build for visionOS:"
echo "   1. Open Xcode"
echo "   2. Select visionOS target"
echo "   3. Build and run"
echo ""
echo "💡 The app will use:"
echo "   • SwiftData for local storage"
echo "   • CloudKit for sync"
echo "   • No Firebase dependencies"
echo "   • Anonymous user creation"
echo "   • visionOS-optimized UI" 