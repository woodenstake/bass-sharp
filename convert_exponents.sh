#!/bin/bash

# Check if input file is provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <input.csv> <column_number> [output.csv]"
    echo "Example: $0 input.csv 2 output.csv"
    echo "If output file is not specified, will print to stdout"
    exit 1
fi

INPUT_FILE="$1"
COLUMN_NUM="$2"
OUTPUT_FILE="$3"

# Function to convert scientific notation to decimal
convert_scientific() {
    local number="$1"
    if [[ $number =~ ^[0-9]*\.?[0-9]*e[+-][0-9]+$ ]]; then
        # It's in scientific notation - convert it
        printf "%.15f" "$number"
    else
        # Not in scientific notation - return as is
        echo "$number"
    fi
}

# Process the CSV file
process_csv() {
    local line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        
        # Keep the header line unchanged
        if [ $line_num -eq 1 ]; then
            echo "$line"
            continue
        fi
        
        # Split line into fields
        IFS=';' read -ra fields <<< "$line"
        
        # Check if column number is valid
        if [ "${COLUMN_NUM}" -gt "${#fields[@]}" ]; then
            echo "Error: Column $COLUMN_NUM doesn't exist in line $line_num" >&2
            continue
        fi
        
        # Convert the value in the specified column (0-indexed array)
        column_index=$((COLUMN_NUM - 1))
        original_value="${fields[$column_index]}"
        converted_value=$(convert_scientific "$original_value")
        fields[$column_index]="$converted_value"
        
        # Reconstruct the line
        new_line=""
        for i in "${!fields[@]}"; do
            if [ $i -eq 0 ]; then
                new_line="${fields[$i]}"
            else
                new_line="${new_line};${fields[$i]}"
            fi
        done
        
        echo "$new_line"
    done < "$INPUT_FILE"
}

# Run the processing and handle output
if [ -n "$OUTPUT_FILE" ]; then
    process_csv > "$OUTPUT_FILE"
    echo "Converted file saved to: $OUTPUT_FILE"
else
    process_csv
fi