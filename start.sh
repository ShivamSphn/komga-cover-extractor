#!/bin/bash

# Display environment variables if set
[ ! -z "$PATHS" ] && echo "PATHS: $PATHS"
[ ! -z "$DOWNLOAD_FOLDERS" ] && echo "DOWNLOAD_FOLDERS: $DOWNLOAD_FOLDERS"
[ ! -z "$WEBHOOK" ] && echo "WEBHOOK: $WEBHOOK"
[ ! -z "$BOOKWALKER_CHECK" ] && echo "BOOKWALKER_CHECK: $BOOKWALKER_CHECK"
[ ! -z "$COMPRESS" ] && echo "COMPRESS: $COMPRESS"
[ ! -z "$COMPRESS_QUALITY" ] && echo "COMPRESS_QUALITY: $COMPRESS_QUALITY"
[ ! -z "$BOOKWALKER_WEBHOOK_URLS" ] && echo "BOOKWALKER_WEBHOOK_URLS: $BOOKWALKER_WEBHOOK_URLS"
[ ! -z "$WATCHDOG" ] && echo "WATCHDOG: $WATCHDOG"
[ ! -z "$WATCHDOG_DISCOVER_NEW_FILES_CHECK_INTERVAL" ] && echo "WATCHDOG_DISCOVER_NEW_FILES_CHECK_INTERVAL: $WATCHDOG_DISCOVER_NEW_FILES_CHECK_INTERVAL"
[ ! -z "$WATCHDOG_FILE_TRANSFERRED_CHECK_INTERVAL" ] && echo "WATCHDOG_FILE_TRANSFERRED_CHECK_INTERVAL: $WATCHDOG_FILE_TRANSFERRED_CHECK_INTERVAL"
[ ! -z "$OUTPUT_COVERS_AS_WEBP" ] && echo "OUTPUT_COVERS_AS_WEBP: $OUTPUT_COVERS_AS_WEBP"
[ ! -z "$NEW_VOLUME_WEBHOOK" ] && echo "NEW_VOLUME_WEBHOOK: $NEW_VOLUME_WEBHOOK"

# Run qbit_torrent_unchecker in background
uv run python3 /app/addons/qbit_torrent_unchecker/qbit_torrent_unchecker.py \
    --paths="$PATHS" \
    --download_folders="$DOWNLOAD_FOLDERS" > /dev/null 2>&1 &

# Run main script
exec uv run python3 -u komga_cover_extractor.py \
    --paths="$PATHS" \
    --download_folders="$DOWNLOAD_FOLDERS" \
    --webhook="$WEBHOOK" \
    --bookwalker_check="$BOOKWALKER_CHECK" \
    --compress="$COMPRESS" \
    --compress_quality="$COMPRESS_QUALITY" \
    --bookwalker_webhook_urls="$BOOKWALKER_WEBHOOK_URLS" \
    --watchdog="$WATCHDOG" \
    --watchdog_discover_new_files_check_interval="$WATCHDOG_DISCOVER_NEW_FILES_CHECK_INTERVAL" \
    --watchdog_file_transferred_check_interval="$WATCHDOG_FILE_TRANSFERRED_CHECK_INTERVAL" \
    --output_covers_as_webp="$OUTPUT_COVERS_AS_WEBP" \
    --new_volume_webhook="$NEW_VOLUME_WEBHOOK"
