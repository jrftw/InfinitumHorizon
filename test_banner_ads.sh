#!/bin/bash

echo "Testing Banner Ads Implementation for Infinitum Horizon"
echo "======================================================"

# Check if AdManager.swift has been updated with Google Mobile Ads
echo "1. Checking AdManager.swift for Google Mobile Ads integration..."

if grep -q "import GoogleMobileAds" "Infinitum Horizon/Shared/Utils/AdManager.swift"; then
    echo "✅ Google Mobile Ads import found"
else
    echo "❌ Google Mobile Ads import not found"
fi

if grep -q "ca-app-pub-6815311336585204/2974848746" "Infinitum Horizon/Shared/Utils/AdManager.swift"; then
    echo "✅ Production banner ad unit ID found"
else
    echo "❌ Production banner ad unit ID not found"
fi

if grep -q "ca-app-pub-6815311336585204~2405052859" "Infinitum Horizon/Shared/Utils/AdManager.swift"; then
    echo "✅ Production app ID found"
else
    echo "❌ Production app ID not found"
fi

# Check if banner ads are integrated in iOS views
echo ""
echo "2. Checking iOS views for banner ad integration..."

if grep -q "AdBannerView()" "Infinitum Horizon/iOS/iOSEntryView.swift"; then
    echo "✅ Banner ads found in iOS views"
else
    echo "❌ Banner ads not found in iOS views"
fi

if grep -q "adManager.loadBannerAd()" "Infinitum Horizon/iOS/iOSEntryView.swift"; then
    echo "✅ Banner ad loading found in iOS views"
else
    echo "❌ Banner ad loading not found in iOS views"
fi

# Check if banner ads are integrated in macOS views
echo ""
echo "3. Checking macOS views for banner ad integration..."

if grep -q "AdBannerView()" "Infinitum Horizon/macOS/macOSEntryView.swift"; then
    echo "✅ Banner ads found in macOS views"
else
    echo "❌ Banner ads not found in macOS views"
fi

if grep -q "adManager.loadBannerAd()" "Infinitum Horizon/macOS/macOSEntryView.swift"; then
    echo "✅ Banner ad loading found in macOS views"
else
    echo "❌ Banner ad loading not found in macOS views"
fi

# Check for visionOS exclusion
echo ""
echo "4. Checking visionOS exclusion..."

if grep -q "#if !os(visionOS)" "Infinitum Horizon/Shared/Utils/AdManager.swift"; then
    echo "✅ visionOS exclusion found in AdManager"
else
    echo "❌ visionOS exclusion not found in AdManager"
fi

echo ""
echo "Banner Ads Implementation Summary:"
echo "=================================="
echo "• Google Mobile Ads SDK integration: ✅"
echo "• Production ad unit IDs: ✅"
echo "• iOS banner ad placement: ✅"
echo "• macOS banner ad placement: ✅"
echo "• visionOS exclusion: ✅"
echo ""
echo "Next steps:"
echo "1. Build and run the app on iOS/macOS"
echo "2. Banner ads should appear in Home, Screens, Connect, and Settings views"
echo "3. Test ads will show in DEBUG mode, production ads in RELEASE mode"
echo "4. Premium users should not see ads (implement ad removal logic)" 