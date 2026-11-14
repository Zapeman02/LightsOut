#!/bin/zsh
# Usage: ./build.sh            -> build/LightsOut.app
#        ./build.sh install    -> also installs to /Applications and launches
#        ./build.sh check      -> runs all tests and a release build
set -e
cd "$(dirname "$0")"

if [[ "$1" == "check" ]]; then
    swift test
    swift build -c release
    echo "All checks passed"
    exit 0
fi

APP="build/LightsOut.app"
swift build -c release
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/LightsOut "$APP/Contents/MacOS/"
cp Info.plist "$APP/Contents/"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
codesign --force --sign - -r='designated => identifier "com.kasperback.lightsout"' "$APP"
echo "Built $APP"

if [[ "$1" == "install" ]]; then
    pkill -x LightsOut || true
    rm -rf /Applications/LightsOut.app
    cp -R "$APP" /Applications/
    open /Applications/LightsOut.app
    echo "Installed and launched"
fi
