#!/bin/bash

# Script to fix reCAPTCHA SDK linking issue on iOS
# This script properly cleans and reinstalls all dependencies

set -e

echo "🧹 Cleaning Flutter build..."
flutter clean

echo "📦 Getting Flutter dependencies..."
flutter pub get

echo "📍 Navigating to iOS directory..."
cd ios

echo "🗑️ Removing Pods and build artifacts..."
rm -rf Pods
rm -rf Podfile.lock
rm -rf Flutter/Flutter.podspec
rm -rf Build
rm -rf .symlinks
rm -rf Flutter/Flutter.framework

echo "🧹 Cleaning Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo "🔧 Running pod repo update..."
pod repo update

echo "📚 Installing pods with reCAPTCHA support..."
pod install --repo-update

echo "✅ Done! iOS project is ready."
echo ""
echo "Next steps:"
echo "1. Open Runner.xcworkspace in Xcode"
echo "2. Clean build folder (Cmd+Shift+K)"
echo "3. Run the app on a physical device for best results"
