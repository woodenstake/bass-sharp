#!/bin/bash

# Check if input file is provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <input.csv> [output.wav] [column_number]"
    echo "Example: $0 input.csv output.wav 2"
    echo "Default column is 1 if not specified"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="${2:-output.wav}"
COLUMN_NUM="${3:-1}"

# Define variable to store processed data
TEMP_FILE=$(mktemp)

# First pass: find min and max values
MIN_VAL=$(tail -n +2 "$INPUT_FILE" | cut -d';' -f"$COLUMN_NUM" | sort -n | head -1)
MAX_VAL=$(tail -n +2 "$INPUT_FILE" | cut -d';' -f"$COLUMN_NUM" | sort -n | tail -1)

# Create debug output filename
DEBUG_FILE="${OUTPUT_FILE}.debug.txt"

# Second pass: scale and convert
tail -n +2 "$INPUT_FILE" | cut -d';' -f"$COLUMN_NUM" | \
jq -R --arg min "$MIN_VAL" --arg max "$MAX_VAL" '
  . as $line |
  try (
    ($line | tonumber) as $val |
    ($val - ($min | tonumber)) / (($max | tonumber) - ($min | tonumber)) * 65535 - 32768 |
    round | tostring
  ) catch $line
' -r | tee "$DEBUG_FILE" | \
sox -t raw -r 44100 -e signed -b 16 -c 1 - "$OUTPUT_FILE"

echo "Converted CSV to WAV with auto-scaling from $MIN_VAL to $MAX_VAL"
echo "Used column: $COLUMN_NUM"
echo "Output saved to: $OUTPUT_FILE"
echo "Debug values saved to: $DEBUG_FILE"
