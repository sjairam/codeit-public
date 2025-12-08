#!/bin/bash

# Usage: biggest_files <folder> [num_files]
# Shows the largest files in the given folder (default: top 20)

FOLDER="$1"
NUM_FILES="${2:-20}"

# Function to print usage
usage() {
  echo "Usage: $0 <folder> [num_files]"
  echo "  <folder>    : Directory to search for biggest files."
  echo "  [num_files] : (Optional) Number of files to show. Default is 20."
}

# Check if a parameter was given
if [ -z "$FOLDER" ]; then
  usage
  exit 1
fi

# Check if folder exists and is a directory
if [ ! -d "$FOLDER" ]; then
  echo "❌ Error: '$FOLDER' is not a valid directory."
  exit 2
fi

# Check if NUM_FILES is a positive integer
if ! [[ "$NUM_FILES" =~ ^[0-9]+$ ]] || [ "$NUM_FILES" -le 0 ]; then
  echo "❌ Error: num_files must be a positive integer."
  usage
  exit 3
fi

# Main logic
echo "🔎 Searching for the biggest files in: $FOLDER"
echo "--------------------------------------------"

# Use du efficiently, sort, and format output
find "$FOLDER" -type f -print0 2>/dev/null | \
  xargs -0 du -h 2>/dev/null | \
  sort -rh | \
  head -n "$NUM_FILES" | \
  awk '{printf "%-10s %s\n", $1, $2}'

