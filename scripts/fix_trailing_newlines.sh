#!/bin/bash
# Usage: ./fix_trailing_newlines.sh file1.java file2.java ...
# Removes trailing spaces and ensures exactly one newline at end of file for each argument

for file in "$@"; do
  sed -i '' -e 's/[[:space:]]*$//' -e '$a\
' "$file"
done 