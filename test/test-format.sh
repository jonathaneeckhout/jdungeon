#!/bin/sh

non_formatted_files=$(find scenes scripts -name "*.gd" -exec gdformat --check {} \; 2>&1 | grep -v "1 file would be left unchanged")
if [ -n "$non_formatted_files" ]; then
  echo "Some files in specified directories are not well-formatted. Please run 'gdformat' to fix them:"
  echo "$non_formatted_files"
  exit 1
else
  echo "All files in specified directories are well-formatted."
fi