#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Move to one directory above the script directory
cd "$SCRIPT_DIR/.."

# Read the templates from files
README_WEB_TEMPLATE=$(cat "$SCRIPT_DIR/readme.web.md")
README_CONSOLE_TEMPLATE=$(cat "$SCRIPT_DIR/readme.console.md")

# Skip
skip_projects=("terminalgpt")

# List of console languages
console_languages=("curl")

# Iterate through each directory looking for a Dockerfile
for dir in */; do
  if [ -f "${dir}Dockerfile" ]; then
    # Remove the trailing slash from the directory name
    service_name=${dir%/}

    # Check if the service_name is in the skip_projects array
    if [[ " ${skip_projects[@]} " =~ " ${service_name} " ]]; then
      echo "Skipping $service_name"
      continue
    fi

    # Extract the service language
    service_language=$(echo "$service_name" | cut -d'-' -f1)
    
    # Choose the appropriate template based on the service language
    if [[ " ${console_languages[@]} " =~ " ${service_language} " ]]; then
      readme_content=$(echo "$README_CONSOLE_TEMPLATE" | sed "s/{{service_name}}/$service_name/g" | sed "s/{{service_language}}/$service_language/g")
    else
      readme_content=$(echo "$README_WEB_TEMPLATE" | sed "s/{{service_name}}/$service_name/g" | sed "s/{{service_language}}/$service_language/g")
    fi
    
    # Write the content to README.md in the current directory
    echo "$readme_content" > "${dir}README.md"
  fi
done

echo "README.md files generated successfully."

