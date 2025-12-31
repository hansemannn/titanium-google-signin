#!/bin/bash

# 🔍 Google Sign-In Diagnostic Tool for Titanium Android
# This script helps diagnose and configure Google Sign-In by extracting SHA fingerprints
# from all relevant keystores and providing step-by-step Firebase setup instructions

set -e

echo "============================================================"
echo "  🔐 Google Sign-In Diagnostic Tool for Titanium Android"
echo "============================================================"
echo ""
echo "This tool will help you:"
echo "  • Extract SHA-1 and SHA-256 fingerprints from all keystores"
echo "  • Verify your device configuration"
echo "  • Guide you through Firebase Console setup"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Global variables to store fingerprints
FINGERPRINTS_FOUND=()
SUMMARY_FILE="/tmp/titanium-google-signin-fingerprints-$(date +%s).txt"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)    echo "macos";;
        Linux*)     echo "linux";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

# Function to extract fingerprints from keystore
extract_fingerprints() {
    local keystore_path="$1"
    local keystore_alias="$2"
    local keystore_pass="$3"
    local key_pass="$4"
    local label="$5"
    
    if [ ! -f "$keystore_path" ]; then
        echo -e "${YELLOW}  ⚠ Keystore not found: $keystore_path${NC}"
        return 1
    fi
    
    echo -e "${GREEN}  ✓ Found: $keystore_path${NC}"
    echo ""
    
    # Extract certificate info
    local output
    output=$(keytool -list -v -keystore "$keystore_path" -alias "$keystore_alias" \
             -storepass "$keystore_pass" -keypass "$key_pass" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}  ✗ Failed to read keystore${NC}"
        return 1
    fi
    
    # Extract SHA-1
    local sha1
    sha1=$(echo "$output" | grep -i "SHA1:" | head -1 | sed 's/.*SHA1: //' | tr -d ' ')
    if [ -z "$sha1" ]; then
        sha1=$(echo "$output" | grep -i "SHA-1:" | head -1 | sed 's/.*SHA-1: //' | tr -d ' ')
    fi
    
    # Extract SHA-256
    local sha256
    sha256=$(echo "$output" | grep -i "SHA256:" | head -1 | sed 's/.*SHA256: //' | tr -d ' ')
    if [ -z "$sha256" ]; then
        sha256=$(echo "$output" | grep -i "SHA-256:" | head -1 | sed 's/.*SHA-256: //' | tr -d ' ')
    fi
    
    if [ -n "$sha1" ] || [ -n "$sha256" ]; then
        echo -e "${CYAN}  📋 Fingerprints for: $label${NC}"
        
        if [ -n "$sha1" ]; then
            echo -e "     SHA-1:   ${BLUE}$sha1${NC}"
            FINGERPRINTS_FOUND+=("$label|SHA-1|$sha1")
            
            # Try to copy to clipboard (first SHA-1 found)
            if [ ${#FINGERPRINTS_FOUND[@]} -eq 1 ]; then
                if command_exists pbcopy; then
                    echo "$sha1" | pbcopy
                    echo -e "${GREEN}     ✓ SHA-1 copied to clipboard!${NC}"
                elif command_exists xclip; then
                    echo "$sha1" | xclip -selection clipboard
                    echo -e "${GREEN}     ✓ SHA-1 copied to clipboard!${NC}"
                fi
            fi
        fi
        
        if [ -n "$sha256" ]; then
            echo -e "     SHA-256: ${BLUE}$sha256${NC}"
            FINGERPRINTS_FOUND+=("$label|SHA-256|$sha256")
        fi
        
        echo ""
        
        # Save to summary file
        echo "=== $label ===" >> "$SUMMARY_FILE"
        [ -n "$sha1" ] && echo "SHA-1:   $sha1" >> "$SUMMARY_FILE"
        [ -n "$sha256" ] && echo "SHA-256: $sha256" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
        
        return 0
    else
        echo -e "${RED}  ✗ Could not extract fingerprints${NC}"
        return 1
    fi
}

# Function to find latest Titanium SDK version
find_titanium_sdk() {
    local os_type="$1"
    local base_path
    
    case "$os_type" in
        macos)
            base_path="$HOME/Library/Application Support/Titanium/mobilesdk/osx"
            ;;
        linux)
            base_path="$HOME/.titanium/mobilesdk/linux"
            ;;
        windows)
            base_path="$HOME/AppData/Roaming/Titanium/mobilesdk/win32"
            ;;
        *)
            return 1
            ;;
    esac
    
    if [ ! -d "$base_path" ]; then
        return 1
    fi
    
    # Find latest version (sorted)
    local latest_version
    latest_version=$(ls -1 "$base_path" 2>/dev/null | grep -E '^[0-9]+\.' | sort -V | tail -1)
    
    if [ -n "$latest_version" ]; then
        echo "$base_path/$latest_version"
        return 0
    fi
    
    return 1
}

# Function to extract fingerprints from APK
extract_apk_fingerprints() {
    local package_name="$1"
    
    if ! command_exists adb; then
        return 1
    fi
    
    local device_count
    device_count=$(adb devices | grep -c "device$")
    
    if [ "$device_count" -eq 0 ]; then
        return 1
    fi
    
    local apk_path
    apk_path=$(adb shell pm path "$package_name" 2>/dev/null | head -1 | sed 's/package://')
    
    if [ -z "$apk_path" ]; then
        return 1
    fi
    
    echo -e "${GREEN}  ✓ App found on device: $apk_path${NC}"
    
    # Get APK size
    local apk_size
    apk_size=$(adb shell stat -c %s "$apk_path" 2>/dev/null)
    if [ -n "$apk_size" ]; then
        local size_mb=$((apk_size / 1048576))
        echo "  APK size: ${size_mb}MB"
    fi
    
    local tmp_apk="/tmp/extracted_app_$(date +%s).apk"
    echo "  Extracting APK from device..."
    echo ""
    
    # Show adb pull progress
    adb pull "$apk_path" "$tmp_apk"
    local pull_result=$?
    
    echo ""
    
    if [ $pull_result -ne 0 ] || [ ! -f "$tmp_apk" ]; then
        echo -e "${RED}  ✗ Failed to extract APK${NC}"
        return 1
    fi
    
    echo -e "${GREEN}  ✓ APK extracted successfully${NC}"
    
    echo ""
    local output
    output=$(keytool -list -printcert -jarfile "$tmp_apk" 2>/dev/null)
    
    local sha1
    sha1=$(echo "$output" | grep -i "SHA1:" | head -1 | sed 's/.*SHA1: //' | tr -d ' ')
    if [ -z "$sha1" ]; then
        sha1=$(echo "$output" | grep -i "SHA-1:" | head -1 | sed 's/.*SHA-1: //' | tr -d ' ')
    fi
    
    local sha256
    sha256=$(echo "$output" | grep -i "SHA256:" | head -1 | sed 's/.*SHA256: //' | tr -d ' ')
    if [ -z "$sha256" ]; then
        sha256=$(echo "$output" | grep -i "SHA-256:" | head -1 | sed 's/.*SHA-256: //' | tr -d ' ')
    fi
    
    if [ -n "$sha1" ] || [ -n "$sha256" ]; then
        echo -e "${CYAN}  📋 Fingerprints from installed APK${NC}"
        
        [ -n "$sha1" ] && echo -e "     SHA-1:   ${BLUE}$sha1${NC}"
        [ -n "$sha256" ] && echo -e "     SHA-256: ${BLUE}$sha256${NC}"
        echo ""
        
        # Save to summary
        echo "=== Installed APK ($package_name) ===" >> "$SUMMARY_FILE"
        [ -n "$sha1" ] && echo "SHA-1:   $sha1" >> "$SUMMARY_FILE"
        [ -n "$sha256" ] && echo "SHA-256: $sha256" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
        
        [ -n "$sha1" ] && FINGERPRINTS_FOUND+=("Installed APK|SHA-1|$sha1")
        [ -n "$sha256" ] && FINGERPRINTS_FOUND+=("Installed APK|SHA-256|$sha256")
    fi
    
    rm -f "$tmp_apk"
    return 0
}

# Verify prerequisites
echo "============================================================"
echo "  Step 1: Verifying Prerequisites"
echo "============================================================"
echo ""

if ! command_exists keytool; then
    echo -e "${RED}✗ keytool not found!${NC}"
    echo "  Please install JDK and try again."
    exit 1
fi
echo -e "${GREEN}✓ keytool found${NC}"

if command_exists adb; then
    echo -e "${GREEN}✓ adb found${NC}"
    
    # Show connected devices
    echo ""
    echo "  Connected devices:"
    adb devices -l | grep -v "List of devices" | sed 's/^/    /'
else
    echo -e "${YELLOW}⚠ adb not found (optional - needed for device inspection)${NC}"
fi

OS_TYPE=$(detect_os)
echo -e "${GREEN}✓ OS detected: $OS_TYPE${NC}"

echo ""

# Extract fingerprints from Android Debug Keystore
echo "============================================================"
echo "  Step 2: Android Debug Keystore"
echo "============================================================"
echo ""

DEBUG_KEYSTORE="$HOME/.android/debug.keystore"
extract_fingerprints "$DEBUG_KEYSTORE" "androiddebugkey" "android" "android" "Android Debug Keystore"

# Extract fingerprints from Titanium Debug Keystore
echo "============================================================"
echo "  Step 3: Titanium SDK Debug Keystore"
echo "============================================================"
echo ""

TITANIUM_SDK_PATH=$(find_titanium_sdk "$OS_TYPE")

if [ -n "$TITANIUM_SDK_PATH" ]; then
    echo -e "${GREEN}✓ Titanium SDK found: $TITANIUM_SDK_PATH${NC}"
    echo ""
    
    TITANIUM_KEYSTORE="$TITANIUM_SDK_PATH/android/dev_keystore"
    extract_fingerprints "$TITANIUM_KEYSTORE" "tidev" "tirocks" "tirocks" "Titanium Debug Keystore"
else
    echo -e "${YELLOW}⚠ Titanium SDK not found${NC}"
    echo "  Checked: $(case "$OS_TYPE" in
        macos) echo "$HOME/Library/Application Support/Titanium/mobilesdk/osx";;
        linux) echo "$HOME/.titanium/mobilesdk/linux";;
        windows) echo "$HOME/AppData/Roaming/Titanium/mobilesdk/win32";;
        *) echo "Unknown path";;
    esac)"
    echo ""
fi

# Extract fingerprints from Production Keystore
echo "============================================================"
echo "  Step 4: Production Keystore"
echo "============================================================"
echo ""

read -p "Do you have a production/release keystore? (y/n): " has_production

if [[ "$has_production" =~ ^[Yy]$ ]]; then
    echo ""
    read -p "Enter the full path to your production keystore: " PROD_KEYSTORE
    
    if [ -n "$PROD_KEYSTORE" ]; then
        # Expand ~ if present
        PROD_KEYSTORE="${PROD_KEYSTORE/#\~/$HOME}"
        
        echo ""
        read -p "Enter keystore alias (press Enter for 'production'): " PROD_ALIAS
        PROD_ALIAS=${PROD_ALIAS:-production}
        
        echo ""
        read -s -p "Enter keystore password: " PROD_PASS
        echo ""
        
        read -s -p "Enter key password (press Enter if same as keystore password): " KEY_PASS
        KEY_PASS=${KEY_PASS:-$PROD_PASS}
        echo ""
        echo ""
        
        extract_fingerprints "$PROD_KEYSTORE" "$PROD_ALIAS" "$PROD_PASS" "$KEY_PASS" "Production Keystore"
    fi
else
    echo -e "${YELLOW}⚠ Skipping production keystore${NC}"
    echo ""
fi

# Extract from installed APK
echo "============================================================"
echo "  Step 5: Installed APK (Optional)"
echo "============================================================"
echo ""

if command_exists adb; then
    DEVICE_COUNT=$(adb devices | grep -c "device$")
    
    if [ "$DEVICE_COUNT" -gt 0 ]; then
        read -p "Do you want to extract fingerprints from an installed APK? (y/n): " extract_apk
        
        if [[ "$extract_apk" =~ ^[Yy]$ ]]; then
            echo ""
            read -p "Enter your app's package name (e.g., com.titanium.app): " PACKAGE_NAME
            
            if [ -n "$PACKAGE_NAME" ]; then
                echo ""
                echo -e "${YELLOW}Note: APK extraction may take 30-60 seconds for large apps.${NC}"
                echo -e "${YELLOW}Press Ctrl+C at any time to skip this step.${NC}"
                echo ""
                sleep 2
                
                extract_apk_fingerprints "$PACKAGE_NAME" || {
                    echo -e "${YELLOW}  ⚠ APK extraction skipped or failed${NC}"
                    echo ""
                }
            fi
        fi
    else
        echo -e "${YELLOW}⚠ No device connected - skipping APK extraction${NC}"
        echo ""
    fi
else
    echo -e "${YELLOW}⚠ adb not available - skipping APK extraction${NC}"
    echo ""
fi

# Device information
if command_exists adb; then
    DEVICE_COUNT=$(adb devices | grep -c "device$")
    
    if [ "$DEVICE_COUNT" -gt 0 ]; then
        echo "============================================================"
        echo "  Step 6: Device Information"
        echo "============================================================"
        echo ""
        
        echo "Google Play Services version:"
        GPS_VERSION=$(adb shell dumpsys package com.google.android.gms | grep versionName | head -1)
        if [ -n "$GPS_VERSION" ]; then
            echo "  $GPS_VERSION"
        else
            echo -e "  ${YELLOW}Could not retrieve version${NC}"
        fi
        
        echo ""
        echo "Google accounts on device:"
        adb shell dumpsys account | grep -A 1 "com.google" | grep Account | sed 's/^/  /'
        echo ""
    fi
fi

# Summary
echo "============================================================"
echo "  📊 Summary"
echo "============================================================"
echo ""

if [ ${#FINGERPRINTS_FOUND[@]} -eq 0 ]; then
    echo -e "${RED}✗ No fingerprints were extracted!${NC}"
    echo ""
    echo "Please check:"
    echo "  • Keystores exist in the expected locations"
    echo "  • You have the correct passwords"
    echo "  • JDK is properly installed"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Successfully extracted ${#FINGERPRINTS_FOUND[@]} fingerprint(s)!${NC}"
echo ""
echo "All fingerprints have been saved to:"
echo -e "${CYAN}$SUMMARY_FILE${NC}"
echo ""

# Display summary table
echo "Fingerprints found:"
echo "┌─────────────────────────────────────────────────────────────────┐"
printf "${CYAN}"
for fp in "${FINGERPRINTS_FOUND[@]}"; do
    IFS='|' read -r label type value <<< "$fp"
    printf "  %-30s %-8s\n" "$label" "$type"
done
printf "${NC}"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""

# Firebase Console Tutorial
echo "============================================================"
echo "  🔥 Firebase Console Setup Tutorial"
echo "============================================================"
echo ""
echo -e "${MAGENTA}STEP-BY-STEP GUIDE:${NC}"
echo ""
echo "1️⃣  GO TO FIREBASE CONSOLE"
echo "   → https://console.firebase.google.com/"
echo ""
echo "2️⃣  SELECT YOUR PROJECT"
echo "   (or create a new one if you haven't already)"
echo ""
echo "3️⃣  ADD AN ANDROID APP"
echo "   • Click on 'Add app' or the Android icon"
echo "   • Enter your package name (e.g., com.titanium.app)"
echo "   • Download google-services.json (you'll need this later)"
echo ""
echo "4️⃣  GO TO PROJECT SETTINGS"
echo "   • Click the gear icon ⚙️  next to 'Project Overview'"
echo "   • Select 'Project settings'"
echo "   • Scroll down to 'Your apps' section"
echo ""
echo "5️⃣  ADD SHA FINGERPRINTS"
echo "   • Find your Android app in the list"
echo "   • Click 'Add fingerprint'"
echo "   • Paste the SHA-1 from above"
echo "   • Click 'Save'"
echo "   • Repeat for SHA-256 if needed"
echo ""
echo -e "${YELLOW}   ⚠️  IMPORTANT: Add ALL fingerprints you extracted!${NC}"
echo "   • Debug keystore (for development)"
echo "   • Titanium debug keystore (for Titanium development)"
echo "   • Production keystore (for release builds)"
echo ""
echo "6️⃣  ENABLE GOOGLE SIGN-IN"
echo "   • In Firebase Console, go to 'Authentication'"
echo "   • Click 'Get Started' (if first time)"
echo "   • Go to 'Sign-in method' tab"
echo "   • Click on 'Google'"
echo "   • Toggle 'Enable'"
echo "   • Enter a support email"
echo "   • Click 'Save'"
echo ""
echo "7️⃣  GET YOUR WEB CLIENT ID"
echo "   • Still in 'Authentication' → 'Sign-in method' → 'Google'"
echo "   • Look for 'Web client ID' section"
echo "   • Copy this ID (you'll need it in your Titanium code)"
echo ""
echo "   Alternative way:"
echo "   • Go to 'Project Settings' → 'Service accounts'"
echo "   • You'll see all OAuth 2.0 Client IDs"
echo "   • Copy the 'Web client' ID"
echo ""
echo "8️⃣  ADD TO YOUR TITANIUM PROJECT"
echo "   Place google-services.json in:"
echo "   → app/platform/android/google-services.json"
echo ""
echo "9️⃣  UPDATE YOUR TIAPP.XML"
echo "   Add the Google Sign-In module:"
echo ""
echo '   <modules>'
echo '     <module>ti.googlesignin</module>'
echo '   </modules>'
echo ""
echo "🔟  USE IN YOUR CODE"
echo ""
echo "   // Initialize"
echo "   const GoogleSignIn = require('ti.googlesignin');"
echo "   GoogleSignIn.initialize({"
echo "     clientID: 'YOUR_WEB_CLIENT_ID_HERE'"
echo "   });"
echo ""
echo "   // Sign in"
echo "   GoogleSignIn.signIn({"
echo "     success: (e) => {"
echo "       console.log('Signed in:', e.user);"
echo "       console.log('ID Token:', e.idToken);"
echo "     },"
echo "     error: (e) => {"
echo "       console.log('Error:', e.error);"
echo "     }"
echo "   });"
echo ""
echo "============================================================"
echo "  🔍 Troubleshooting"
echo "============================================================"
echo ""
echo "If you still get 'Unknown error' or sign-in fails:"
echo ""
echo "1. VERIFY FINGERPRINTS"
echo "   • Make sure ALL SHA-1 fingerprints are added to Firebase"
echo "   • Check both debug and production keystores"
echo ""
echo "2. CHECK PACKAGE NAME"
echo "   • Must match EXACTLY between Firebase and tiapp.xml"
echo "   • Case-sensitive!"
echo ""
echo "3. USE CORRECT CLIENT ID"
echo "   • Use the WEB Client ID (not Android Client ID)"
echo "   • The Android Client ID is auto-generated by Firebase"
echo ""
echo "4. REBUILD YOUR APP"
echo "   • After adding google-services.json, do a clean build"
echo "   • ti clean"
echo "   • ti build -p android"
echo ""
echo "5. CHECK LOGS"
echo "   Run this to see detailed logs:"
echo "   adb logcat | grep -E 'TiGoogleSignIn|GoogleSignIn|GoogleId'"
echo ""
echo "6. VERIFY GOOGLE PLAY SERVICES"
echo "   • Make sure device has Google Play Services installed"
echo "   • Update to latest version if needed"
echo ""
echo "============================================================"
echo "  📚 Useful Links"
echo "============================================================"
echo ""
echo "Firebase Console:"
echo "→ https://console.firebase.google.com/"
echo ""
echo "Google Cloud Console (for OAuth):"
echo "→ https://console.cloud.google.com/apis/credentials"
echo ""
echo "Firebase Authentication Docs:"
echo "→ https://firebase.google.com/docs/auth/android/google-signin"
echo ""
echo "Titanium Google Sign-In Module:"
echo "→ https://github.com/hansemannn/titanium-google-signin"
echo ""
echo "============================================================"
echo ""
echo -e "${GREEN}✅ Diagnostic complete!${NC}"
echo ""
echo "Summary file saved to:"
echo -e "${CYAN}$SUMMARY_FILE${NC}"
echo ""
echo "You can view it with: cat $SUMMARY_FILE"
echo ""
echo "Good luck with your Google Sign-In integration! 🚀"
echo ""