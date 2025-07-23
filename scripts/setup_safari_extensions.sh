#!/bin/bash

# Safari Extensions Setup Script for Flutter wBlock Plugin
# This script sets up the necessary Safari extensions for the ad blocker

set -e

echo "=== Safari Extensions Setup for wBlock ==="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Define paths
MACOS_DIR="$PROJECT_ROOT/macos"
CLASSES_DIR="$MACOS_DIR/Classes"
SAFARI_EXT_DIR="$CLASSES_DIR/SafariWebExtension"
CONTENT_BLOCKERS_DIR="$CLASSES_DIR/ContentBlockers"

# Check if we're in the right directory
if [ ! -f "$PROJECT_ROOT/pubspec.yaml" ]; then
    echo -e "${RED}Error: pubspec.yaml not found. Please run this script from the flutter_wblock_plugin root directory.${NC}"
    exit 1
fi

echo "Project root: $PROJECT_ROOT"
echo

# Function to check if Safari extension source files exist
check_source_files() {
    echo "Checking for Safari extension source files..."
    
    if [ ! -d "$SAFARI_EXT_DIR/Resources" ]; then
        echo -e "${RED}Error: Safari Web Extension resources not found at $SAFARI_EXT_DIR/Resources${NC}"
        echo "Please ensure the Safari Web Extension files have been properly copied."
        exit 1
    fi
    
    if [ ! -f "$SAFARI_EXT_DIR/Resources/manifest.json" ]; then
        echo -e "${RED}Error: manifest.json not found${NC}"
        exit 1
    fi
    
    if [ ! -f "$SAFARI_EXT_DIR/Resources/src/background.js" ]; then
        echo -e "${RED}Error: background.js not found${NC}"
        exit 1
    fi
    
    if [ ! -f "$SAFARI_EXT_DIR/Resources/src/content.js" ]; then
        echo -e "${RED}Error: content.js not found${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All required source files found${NC}"
    echo
}

# Function to create Xcode projects for Safari extensions
create_safari_extensions() {
    echo "Creating Safari Extension Xcode projects..."
    
    # Create directory for Xcode projects
    EXTENSIONS_DIR="$MACOS_DIR/SafariExtensions"
    mkdir -p "$EXTENSIONS_DIR"
    
    # 1. Create Content Blocker Extension - wBlock Filters
    echo "Creating wBlock-Filters content blocker..."
    FILTERS_EXT="$EXTENSIONS_DIR/wBlock-Filters"
    if [ ! -d "$FILTERS_EXT" ]; then
        mkdir -p "$FILTERS_EXT"
        
        # Create Info.plist
        cat > "$FILTERS_EXT/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>wBlock Filters</string>
    <key>CFBundleIdentifier</key>
    <string>syferlab.wBlock.wBlock-Filters</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>wBlock-Filters</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.Safari.content-blocker</string>
        <key>NSExtensionPrincipalClass</key>
        <string>ContentBlockerRequestHandler</string>
    </dict>
</dict>
</plist>
EOF
        
        # Link ContentBlockerRequestHandler.swift
        ln -sf "$CONTENT_BLOCKERS_DIR/ContentBlockerRequestHandler.swift" "$FILTERS_EXT/"
        
        echo -e "${GREEN}✓ Created wBlock-Filters extension${NC}"
    else
        echo -e "${YELLOW}wBlock-Filters already exists${NC}"
    fi
    
    # 2. Create Content Blocker Extension - wBlock Advance
    echo "Creating wBlock-Advance content blocker..."
    ADVANCE_EXT="$EXTENSIONS_DIR/wBlock-Advance"
    if [ ! -d "$ADVANCE_EXT" ]; then
        mkdir -p "$ADVANCE_EXT"
        
        # Create Info.plist
        cat > "$ADVANCE_EXT/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>wBlock Advance</string>
    <key>CFBundleIdentifier</key>
    <string>syferlab.wBlock.wBlock-Advance</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>wBlock-Advance</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.Safari.content-blocker</string>
        <key>NSExtensionPrincipalClass</key>
        <string>ContentBlockerRequestHandler</string>
    </dict>
</dict>
</plist>
EOF
        
        # Link ContentBlockerRequestHandler.swift
        ln -sf "$CONTENT_BLOCKERS_DIR/ContentBlockerRequestHandler.swift" "$ADVANCE_EXT/"
        
        echo -e "${GREEN}✓ Created wBlock-Advance extension${NC}"
    else
        echo -e "${YELLOW}wBlock-Advance already exists${NC}"
    fi
    
    # 3. Create Safari Web Extension - wBlock Scripts
    echo "Creating wBlock-Scripts web extension..."
    SCRIPTS_EXT="$EXTENSIONS_DIR/wBlock-Scripts"
    if [ ! -d "$SCRIPTS_EXT" ]; then
        mkdir -p "$SCRIPTS_EXT"
        
        # Create Info.plist
        cat > "$SCRIPTS_EXT/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>wBlock Scripts</string>
    <key>CFBundleIdentifier</key>
    <string>syferlab.wBlock.wBlock-Scripts</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>wBlock-Scripts</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.Safari.web-extension</string>
        <key>NSExtensionPrincipalClass</key>
        <string>SafariExtensionHandler</string>
    </dict>
    <key>SFSafariWebExtensionBundleIdentifier</key>
    <string>syferlab.wBlock</string>
    <key>SFSafariWebExtensionManifest</key>
    <string>manifest.json</string>
    <key>SFSafariAppExtensionCompatibilityVersion</key>
    <integer>1</integer>
</dict>
</plist>
EOF
        
        # Link SafariExtensionHandler.swift
        ln -sf "$SAFARI_EXT_DIR/SafariExtensionHandler.swift" "$SCRIPTS_EXT/"
        
        # Copy Resources
        cp -R "$SAFARI_EXT_DIR/Resources" "$SCRIPTS_EXT/"
        
        echo -e "${GREEN}✓ Created wBlock-Scripts extension${NC}"
    else
        echo -e "${YELLOW}wBlock-Scripts already exists${NC}"
    fi
    
    echo
}

# Function to create entitlements files
create_entitlements() {
    echo "Creating entitlements files..."
    
    # App Group entitlements for content blockers
    CONTENT_BLOCKER_ENTITLEMENTS="$EXTENSIONS_DIR/ContentBlocker.entitlements"
    cat > "$CONTENT_BLOCKER_ENTITLEMENTS" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.syferlab.wBlock</string>
    </array>
</dict>
</plist>
EOF
    
    # Web Extension entitlements
    WEB_EXT_ENTITLEMENTS="$EXTENSIONS_DIR/WebExtension.entitlements"
    cat > "$WEB_EXT_ENTITLEMENTS" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.syferlab.wBlock</string>
    </array>
    <key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
    <array>
        <string>syferlab.wBlock.wBlock-Scripts</string>
    </array>
</dict>
</plist>
EOF
    
    echo -e "${GREEN}✓ Created entitlements files${NC}"
    echo
}

# Function to verify installation
verify_installation() {
    echo "Verifying installation..."
    
    # Check for required files
    local all_good=true
    
    # Check content blocker files
    if [ ! -f "$EXTENSIONS_DIR/wBlock-Filters/Info.plist" ]; then
        echo -e "${RED}✗ wBlock-Filters Info.plist missing${NC}"
        all_good=false
    fi
    
    if [ ! -f "$EXTENSIONS_DIR/wBlock-Advance/Info.plist" ]; then
        echo -e "${RED}✗ wBlock-Advance Info.plist missing${NC}"
        all_good=false
    fi
    
    # Check web extension files
    if [ ! -f "$EXTENSIONS_DIR/wBlock-Scripts/Info.plist" ]; then
        echo -e "${RED}✗ wBlock-Scripts Info.plist missing${NC}"
        all_good=false
    fi
    
    if [ ! -d "$EXTENSIONS_DIR/wBlock-Scripts/Resources" ]; then
        echo -e "${RED}✗ wBlock-Scripts Resources missing${NC}"
        all_good=false
    fi
    
    # Check critical JavaScript files
    if [ ! -f "$EXTENSIONS_DIR/wBlock-Scripts/Resources/src/background.js" ]; then
        echo -e "${RED}✗ background.js missing${NC}"
        all_good=false
    fi
    
    if [ ! -f "$EXTENSIONS_DIR/wBlock-Scripts/Resources/src/content.js" ]; then
        echo -e "${RED}✗ content.js missing${NC}"
        all_good=false
    fi
    
    # Check scriptlets directory
    if [ ! -d "$EXTENSIONS_DIR/wBlock-Scripts/Resources/web_accessible_resources/scriptlets" ]; then
        echo -e "${RED}✗ Scriptlets directory missing${NC}"
        all_good=false
    else
        scriptlet_count=$(ls "$EXTENSIONS_DIR/wBlock-Scripts/Resources/web_accessible_resources/scriptlets" | wc -l)
        echo -e "${GREEN}✓ Found $scriptlet_count scriptlets${NC}"
    fi
    
    # Check entitlements
    if [ ! -f "$EXTENSIONS_DIR/ContentBlocker.entitlements" ]; then
        echo -e "${RED}✗ ContentBlocker.entitlements missing${NC}"
        all_good=false
    fi
    
    if [ ! -f "$EXTENSIONS_DIR/WebExtension.entitlements" ]; then
        echo -e "${RED}✗ WebExtension.entitlements missing${NC}"
        all_good=false
    fi
    
    # Check symlinks
    if [ ! -L "$EXTENSIONS_DIR/wBlock-Filters/ContentBlockerRequestHandler.swift" ]; then
        echo -e "${RED}✗ wBlock-Filters ContentBlockerRequestHandler.swift symlink missing${NC}"
        all_good=false
    fi
    
    if [ ! -L "$EXTENSIONS_DIR/wBlock-Scripts/SafariExtensionHandler.swift" ]; then
        echo -e "${RED}✗ wBlock-Scripts SafariExtensionHandler.swift symlink missing${NC}"
        all_good=false
    fi
    
    if [ "$all_good" = true ]; then
        echo -e "${GREEN}✓ All extension files verified${NC}"
    else
        echo -e "${RED}Some files are missing. Please check the setup.${NC}"
        exit 1
    fi
    
    echo
}

# Function to update project files
update_project_instructions() {
    echo "=== Manual Steps Required ==="
    echo
    echo "1. Open your macOS app project in Xcode (usually macos/Runner.xcworkspace)"
    echo
    echo "2. Add Safari Extension targets:"
    echo "   For Content Blockers:"
    echo "   - File → New → Target → Safari Extension"
    echo "   - Name: 'wBlock-Filters'"
    echo "   - Bundle ID: syferlab.wBlock.wBlock-Filters"
    echo "   - Repeat for 'wBlock-Advance'"
    echo
    echo "   For Web Extension:"
    echo "   - File → New → Target → Safari Web Extension"
    echo "   - Name: 'wBlock-Scripts'"
    echo "   - Bundle ID: syferlab.wBlock.wBlock-Scripts"
    echo
    echo "3. Configure each extension:"
    echo "   - Set deployment target to macOS 10.15 or later"
    echo "   - Add app group capability: group.syferlab.wBlock"
    echo "   - Use the appropriate entitlements file from $EXTENSIONS_DIR"
    echo
    echo "4. Replace the auto-generated extension files with:"
    echo "   - Content Blockers: Use ContentBlockerRequestHandler.swift"
    echo "   - Web Extension: Copy entire Resources folder"
    echo
    echo "5. Update native messaging in SafariExtensionHandler.swift:"
    echo "   - Ensure NATIVE_APP_ID = \"syferlab.wBlock.wBlock-Scripts\""
    echo
    echo "6. Build and run your app"
    echo
    echo "Extensions created at: $EXTENSIONS_DIR"
    echo
}

# Main execution
main() {
    echo "Starting Safari extensions setup..."
    echo "Architecture: Content Blockers + Safari Web Extension"
    echo
    
    check_source_files
    create_safari_extensions
    create_entitlements
    verify_installation
    update_project_instructions
    
    echo -e "${GREEN}✓ Safari extensions setup completed!${NC}"
    echo
    echo "The setup has created:"
    echo "- 2 Content Blocker extensions (network & CSS blocking)"
    echo "- 1 Safari Web Extension (JavaScript & scriptlet injection)"
    echo
    echo "Next steps:"
    echo "1. Follow the manual steps above to add extensions to Xcode"
    echo "2. Build and test your app with Safari"
    echo "3. Enable all three extensions in Safari Preferences → Extensions"
    echo "4. Test YouTube ad blocking functionality"
}

# Run main function
main
