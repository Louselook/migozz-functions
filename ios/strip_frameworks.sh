#!/bin/sh

################################################################################
# Script to strip invalid architectures from embedded frameworks
# This fixes ITMS-91169 and ITMS-90208 errors when submitting to App Store
################################################################################

echo "🔧 Stripping invalid architectures from frameworks..."

# Get the path to the built app
APP_PATH="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"

# Find all frameworks in the app
find "$APP_PATH" -name '*.framework' -type d | while read -r FRAMEWORK
do
    FRAMEWORK_EXECUTABLE_NAME=$(defaults read "$FRAMEWORK/Info.plist" CFBundleExecutable 2>/dev/null)
    
    if [ -z "$FRAMEWORK_EXECUTABLE_NAME" ]; then
        # If Info.plist doesn't exist or doesn't have CFBundleExecutable, use framework name
        FRAMEWORK_EXECUTABLE_NAME=$(basename "$FRAMEWORK" .framework)
    fi
    
    FRAMEWORK_EXECUTABLE_PATH="$FRAMEWORK/$FRAMEWORK_EXECUTABLE_NAME"
    
    if [ ! -f "$FRAMEWORK_EXECUTABLE_PATH" ]; then
        echo "⚠️  Executable not found: $FRAMEWORK_EXECUTABLE_PATH"
        continue
    fi
    
    echo "📦 Processing: $(basename "$FRAMEWORK")"
    
    # Get current architectures
    ARCHS="$(lipo -info "$FRAMEWORK_EXECUTABLE_PATH" | rev | cut -d ':' -f1 | rev)"
    
    echo "   Current architectures: $ARCHS"
    
    # Strip simulator architectures (x86_64, i386, arm64-simulator)
    for ARCH in $ARCHS
    do
        # Check if this is a simulator architecture
        if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "i386" ]; then
            echo "   ❌ Removing simulator architecture: $ARCH"
            lipo -remove "$ARCH" -output "$FRAMEWORK_EXECUTABLE_PATH" "$FRAMEWORK_EXECUTABLE_PATH" || exit 1
        fi
    done
    
    # Verify final architectures
    FINAL_ARCHS="$(lipo -info "$FRAMEWORK_EXECUTABLE_PATH" | rev | cut -d ':' -f1 | rev)"
    echo "   ✅ Final architectures: $FINAL_ARCHS"
    
    # Code sign the framework after modification
    if [ "$CODE_SIGNING_REQUIRED" = "YES" ]; then
        echo "   🔐 Code signing framework..."
        /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --preserve-metadata=identifier,entitlements "$FRAMEWORK_EXECUTABLE_PATH"
    fi
done

echo "✅ Framework stripping complete!"

