#!/bin/bash

echo "Adding Google Mobile Ads SDK to Infinitum Horizon project..."

# Navigate to project directory
cd "$(dirname "$0")"

# Add Google Mobile Ads SDK via Swift Package Manager
# The package URL for Google Mobile Ads SDK
PACKAGE_URL="https://github.com/googleads/swift-package-manager-google-mobile-ads.git"

echo "Adding Google Mobile Ads SDK package: $PACKAGE_URL"

# This will need to be done manually in Xcode, but here's the command structure
echo ""
echo "To add Google Mobile Ads SDK to your project:"
echo "1. Open Infinitum Horizon.xcodeproj in Xcode"
echo "2. Go to File > Add Package Dependencies..."
echo "3. Enter the URL: $PACKAGE_URL"
echo "4. Click 'Add Package'"
echo "5. Select the target 'Infinitum Horizon'"
echo "6. Click 'Add Package'"
echo ""
echo "After adding the package, the AdManager will be ready to use with real ads!"

echo "Script completed!" 