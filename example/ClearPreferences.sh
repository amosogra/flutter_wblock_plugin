APP_ID="syferlab.wBlock"
APP_NAME="Syferlab Blocker"

# Delete preferences
defaults delete "$APP_ID" 2>/dev/null
rm -f "$HOME/Library/Preferences/$APP_ID.plist"

# Delete Application Support files
rm -rf "$HOME/Library/Application Support/$APP_NAME"

# Delete Saved State
rm -rf "$HOME/Library/Saved Application State/$APP_ID.savedState"

# Delete Caches
rm -rf "$HOME/Library/Caches/$APP_ID"

# Delete any Secure Storage (if using flutter_secure_storage)
security delete-generic-password -s "$APP_NAME" 2>/dev/null
security delete-generic-password -a "$APP_NAME" 2>/dev/null

echo "✅ All preferences and saved data for $APP_NAME have been removed."
