#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
mkdir -p .build/cache dist/Gamebox.app/Contents/MacOS
export CLANG_MODULE_CACHE_PATH="$PWD/.build/cache"
export SWIFT_MODULECACHE_PATH="$PWD/.build/cache"
cat > dist/Gamebox.app/Contents/Info.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Gamebox</string>
<key>CFBundleIdentifier</key><string>dev.gamebox.bottles</string>
<key>CFBundleName</key><string>Gamebox</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.1</string>
<key>CFBundleVersion</key><string>1</string>
<key>GameboxRepository</key><string>Sidhved-Pillai/Gamebox</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
</dict></plist>
EOF
xcrun swiftc -parse-as-library -O -target arm64-apple-macos14.0 -framework AppKit Sources/*.swift -o dist/Gamebox.app/Contents/MacOS/Gamebox
codesign --force --deep --sign - dist/Gamebox.app
ditto -c -k --sequesterRsrc --keepParent dist/Gamebox.app dist/Gamebox.zip
