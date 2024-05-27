#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Move to one directory above the script directory
cd "$SCRIPT_DIR/.."

# Read the template from files
README_TEMPLATE=$(cat "$SCRIPT_DIR/readme.tmpl.md")

# Iterate through each directory looking for a Dockerfile
for dir in */; do
  if [ -f "${dir}Dockerfile" ]; then
    # Remove the trailing slash from the directory name
    service_name=${dir%/}
    # Extract the service language
    service_language=$(echo "$service_name" | cut -d'-' -f1)
    
    # Replace placeholders in README template
    readme_content=$(echo "$README_TEMPLATE" | sed "s/{{service_name}}/$service_name/g" | sed "s/{{service_language}}/$service_language/g")
    
    # Write the content to README.md in the current directory
    echo "$readme_content" > "${dir}README.md"
  fi
done

echo "README.md files generated successfully."
