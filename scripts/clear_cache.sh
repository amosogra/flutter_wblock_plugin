#!/bin/bash

# Clear cached Safari content blocker JSON files
# This forces the converter to re-process filter lists with the fixed rules

APP_GROUP="group.syferlab.wBlock"
CONTAINER_PATH="$HOME/Library/Group Containers/$APP_GROUP"

if [ ! -d "$CONTAINER_PATH" ]; then
    echo "Container path not found: $CONTAINER_PATH"
    exit 1
fi

echo "Clearing cached content blocker JSON files..."

# Remove all JSON files except the configuration files
find "$CONTAINER_PATH" -name "*.json" -type f | while read file; do
    basename=$(basename "$file")
    # Skip configuration files
    if [[ "$basename" != "scriptlet_config.json" && "$basename" != "youtube_scriptlets.json" ]]; then
        echo "Removing: $basename"
        rm -f "$file"
    fi
done

# Also clear the main blocker lists
rm -f "$CONTAINER_PATH/blockerList.json"
rm -f "$CONTAINER_PATH/blockerList2.json"

echo "Cached files cleared. The next update will re-convert all filter lists."
echo "Please run 'Update Filters' in the app to apply the fixed conversion rules."