#!/usr/bin/env bash
set -euo pipefail

WORK_DIR="${1:-$HOME/work}"
OUTPUT_DIR="${2:-$WORK_DIR/zipped}"

mkdir -p "$OUTPUT_DIR"

echo "Zipping folders in: $WORK_DIR"
echo "Output directory:   $OUTPUT_DIR"
echo ""

count=0
for dir in "$WORK_DIR"/*/; do
    [[ -d "$dir" ]] || continue

    folder_name="$(basename "$dir")"

    # Skip the output directory itself
    [[ "$dir" == "$OUTPUT_DIR"/ ]] && continue
    [[ "$(realpath "$dir")" == "$(realpath "$OUTPUT_DIR")" ]] && continue

    zip_file="$OUTPUT_DIR/${folder_name}.zip"
    echo "  Zipping: $folder_name → ${zip_file##*/}"
    (cd "$WORK_DIR" && zip -rq "$zip_file" "$folder_name")
    count=$((count + 1))
done

echo ""
echo "Done. $count folder(s) zipped into: $OUTPUT_DIR"
