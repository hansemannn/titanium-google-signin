#!/bin/sh
#
# Rebuilds the bundled GoogleSignIn SDK from its CocoaPod:
#   platform/*.xcframework  static frameworks (iOS device, iOS simulator, Mac Catalyst)
#   Resources/*.bundle      resource bundles, incl. each SDK's privacy manifest (PrivacyInfo.xcprivacy)
#
# Usage (on macOS with Xcode, CocoaPods and XcodeGen): ios/update-google-signin-sdk.sh [version] [AppCheckCore version]
#
set -e

VERSION="${1:-10.1.0}"
# AppCheckCore 12 is not on the CocoaPods trunk; use its podspec from the tagged release.
APP_CHECK_CORE_VERSION="${2:-12.1.0}"
IOS_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cd "$WORK"
mkdir App
cat > App/project.yml <<EOF
name: App
options:
  deploymentTarget:
    iOS: "15.0"
targets:
  App:
    type: application
    platform: iOS
    sources: []
EOF
(cd App && xcodegen generate --quiet)

cat > Podfile <<EOF
platform :ios, '15.0'
project 'App/App.xcodeproj'
install! 'cocoapods', integrate_targets: false
use_frameworks! :linkage => :static
target 'App' do
  pod 'GoogleSignIn', '$VERSION'
  pod 'AppCheckCore', :podspec => 'https://raw.githubusercontent.com/google/app-check/$APP_CHECK_CORE_VERSION/AppCheckCore.podspec'
end
EOF
pod install --repo-update

build() { # $1 = destination, $2 = output folder
  xcodebuild build -quiet \
    -project Pods/Pods.xcodeproj -scheme Pods-App -configuration Release \
    -destination "$1" -derivedDataPath DerivedData \
    SYMROOT="$WORK/build/$2" BUILD_LIBRARY_FOR_DISTRIBUTION=YES SKIP_INSTALL=NO \
    SUPPORTS_MACCATALYST=YES IPHONEOS_DEPLOYMENT_TARGET=15.0 DEBUG_INFORMATION_FORMAT=dwarf
}
build 'generic/platform=iOS' device
build 'generic/platform=iOS Simulator' simulator
build 'generic/platform=macOS,variant=Mac Catalyst' catalyst

rm -rf "$IOS_DIR"/platform/*.xcframework "$IOS_DIR"/Resources/*.bundle
mkdir -p "$IOS_DIR/platform" "$IOS_DIR/Resources"

for framework in build/device/Release-iphoneos/*/*.framework; do
  pod_dir="$(basename "$(dirname "$framework")")"
  name="$(basename "$framework" .framework)"
  xcodebuild -create-xcframework \
    -framework "$framework" \
    -framework "build/simulator/Release-iphonesimulator/$pod_dir/$name.framework" \
    -framework "build/catalyst/Release-maccatalyst/$pod_dir/$name.framework" \
    -output "$IOS_DIR/platform/$name.xcframework"
done

# ABI baselines and source info are only for the SDK's own tooling
find "$IOS_DIR/platform" -name '*.abi.json' -delete
find "$IOS_DIR/platform" -path '*.swiftmodule/Project' -prune -exec rm -rf {} +

# Resource bundles (the app copies the module's Resources folder into its bundle).
for bundle in build/device/Release-iphoneos/*/*.bundle; do
  cp -R "$bundle" "$IOS_DIR/Resources/"
done

sed -n '/^PODS:/,/^$/p' Podfile.lock
