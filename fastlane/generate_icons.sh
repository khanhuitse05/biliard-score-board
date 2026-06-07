#!/bin/bash

# Script to generate all app icons from a single 1024x1024 source icon
# Usage: ./generate_icons.sh [source_icon_path]

SOURCE_ICON="${1:-input/images/icon.png}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ ! -f "$SCRIPT_DIR/$SOURCE_ICON" ]; then
    echo "❌ Error: Source icon not found at $SCRIPT_DIR/$SOURCE_ICON"
    exit 1
fi

echo "🖼️  Generating app icons from $SOURCE_ICON"

# Function to resize icon using sips
resize_icon() {
    local size=$1
    local output=$2
    sips -z $size $size "$SCRIPT_DIR/$SOURCE_ICON" --out "$output" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "  ✓ Generated $output ($size x $size)"
    else
        echo "  ✗ Failed to generate $output"
    fi
}

# Android icons
echo ""
echo "📱 Generating Android icons..."
ANDROID_RES="$PROJECT_ROOT/android/app/src/main/res"
resize_icon 48 "$ANDROID_RES/mipmap-mdpi/ic_launcher.png"
resize_icon 72 "$ANDROID_RES/mipmap-hdpi/ic_launcher.png"
resize_icon 96 "$ANDROID_RES/mipmap-xhdpi/ic_launcher.png"
resize_icon 144 "$ANDROID_RES/mipmap-xxhdpi/ic_launcher.png"
resize_icon 192 "$ANDROID_RES/mipmap-xxxhdpi/ic_launcher.png"

# iOS icons
echo ""
echo "🍎 Generating iOS icons..."
IOS_ICONS="$PROJECT_ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset"
resize_icon 40 "$IOS_ICONS/Icon-App-20x20@2x.png"
resize_icon 60 "$IOS_ICONS/Icon-App-20x20@3x.png"
resize_icon 29 "$IOS_ICONS/Icon-App-29x29@1x.png"
resize_icon 58 "$IOS_ICONS/Icon-App-29x29@2x.png"
resize_icon 87 "$IOS_ICONS/Icon-App-29x29@3x.png"
resize_icon 80 "$IOS_ICONS/Icon-App-40x40@2x.png"
resize_icon 120 "$IOS_ICONS/Icon-App-40x40@3x.png"
resize_icon 120 "$IOS_ICONS/Icon-App-60x60@2x.png"
resize_icon 180 "$IOS_ICONS/Icon-App-60x60@3x.png"
resize_icon 20 "$IOS_ICONS/Icon-App-20x20@1x.png"
resize_icon 40 "$IOS_ICONS/Icon-App-20x20@2x.png"
resize_icon 29 "$IOS_ICONS/Icon-App-29x29@1x.png"
resize_icon 58 "$IOS_ICONS/Icon-App-29x29@2x.png"
resize_icon 40 "$IOS_ICONS/Icon-App-40x40@1x.png"
resize_icon 80 "$IOS_ICONS/Icon-App-40x40@2x.png"
resize_icon 76 "$IOS_ICONS/Icon-App-76x76@1x.png"
resize_icon 152 "$IOS_ICONS/Icon-App-76x76@2x.png"
resize_icon 167 "$IOS_ICONS/Icon-App-83.5x83.5@2x.png"
resize_icon 1024 "$IOS_ICONS/Icon-App-1024x1024@1x.png"

# macOS icons
echo ""
echo "💻 Generating macOS icons..."
MACOS_ICONS="$PROJECT_ROOT/macos/Runner/Assets.xcassets/AppIcon.appiconset"
resize_icon 16 "$MACOS_ICONS/app_icon_16.png"
resize_icon 32 "$MACOS_ICONS/app_icon_32.png"
resize_icon 32 "$MACOS_ICONS/app_icon_32.png"
resize_icon 64 "$MACOS_ICONS/app_icon_64.png"
resize_icon 128 "$MACOS_ICONS/app_icon_128.png"
resize_icon 256 "$MACOS_ICONS/app_icon_256.png"
resize_icon 256 "$MACOS_ICONS/app_icon_256.png"
resize_icon 512 "$MACOS_ICONS/app_icon_512.png"
resize_icon 512 "$MACOS_ICONS/app_icon_512.png"
resize_icon 1024 "$MACOS_ICONS/app_icon_1024.png"

# Web icons
echo ""
echo "🌐 Generating Web icons..."
WEB_ICONS="$PROJECT_ROOT/web/icons"
# Create maskable icons with padding (80% of size for safe area)
sips -z 192 192 "$SCRIPT_DIR/$SOURCE_ICON" --out "$WEB_ICONS/Icon-192.png" > /dev/null 2>&1
sips -z 512 512 "$SCRIPT_DIR/$SOURCE_ICON" --out "$WEB_ICONS/Icon-512.png" > /dev/null 2>&1
# For maskable icons, we'll create them with padding (using ImageMagick if available)
if command -v magick &> /dev/null; then
    magick "$SCRIPT_DIR/$SOURCE_ICON" -resize 154x154 -gravity center -extent 192x192 -background transparent "$WEB_ICONS/Icon-maskable-192.png" 2>/dev/null
    magick "$SCRIPT_DIR/$SOURCE_ICON" -resize 410x410 -gravity center -extent 512x512 -background transparent "$WEB_ICONS/Icon-maskable-512.png" 2>/dev/null
    echo "  ✓ Generated Icon-192.png (192 x 192)"
    echo "  ✓ Generated Icon-512.png (512 x 512)"
    echo "  ✓ Generated Icon-maskable-192.png (192 x 192)"
    echo "  ✓ Generated Icon-maskable-512.png (512 x 512)"
else
    # Fallback: copy regular icons if ImageMagick not available
    cp "$WEB_ICONS/Icon-192.png" "$WEB_ICONS/Icon-maskable-192.png"
    cp "$WEB_ICONS/Icon-512.png" "$WEB_ICONS/Icon-maskable-512.png"
    echo "  ✓ Generated Icon-192.png (192 x 192)"
    echo "  ✓ Generated Icon-512.png (512 x 512)"
    echo "  ⚠️  ImageMagick not found, using regular icons for maskable versions"
fi

# Web favicon
sips -z 32 32 "$SCRIPT_DIR/$SOURCE_ICON" --out "$PROJECT_ROOT/web/favicon.png" > /dev/null 2>&1
echo "  ✓ Generated favicon.png (32 x 32)"

# Windows icon (ICO format)
echo ""
echo "🪟 Generating Windows icon..."
if command -v magick &> /dev/null; then
    # Create ICO with multiple sizes
    magick "$SCRIPT_DIR/$SOURCE_ICON" \
        \( -clone 0 -resize 16x16 \) \
        \( -clone 0 -resize 32x32 \) \
        \( -clone 0 -resize 48x48 \) \
        \( -clone 0 -resize 64x64 \) \
        \( -clone 0 -resize 128x128 \) \
        \( -clone 0 -resize 256x256 \) \
        -delete 0 \
        "$PROJECT_ROOT/windows/runner/resources/app_icon.ico" 2>/dev/null
    echo "  ✓ Generated app_icon.ico (multi-size)"
else
    echo "  ⚠️  ImageMagick not found, skipping Windows ICO generation"
    echo "     Install ImageMagick: brew install imagemagick"
fi

echo ""
echo "✅ Icon generation complete!"
