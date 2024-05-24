#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Move to one directory above the script directory
cd "$SCRIPT_DIR/.."

# Read the templates from files
DOCKER_COMPOSE_HEADER=$(cat "$SCRIPT_DIR/compose-header.yml")
QTAP_LOCAL_SERVICE=$(cat "$SCRIPT_DIR/qtap-service.yml")
SERVICE_TEMPLATE=$(cat "$SCRIPT_DIR/service-template.yml")

# Initialize the services array and port
services=()
startPort=4000
port=$startPort

# Prepare table header
echo "-----------------------------------------"
printf "| %-20s | %-5s |\n" "Service Name" "Port"
echo "-----------------------------------------"

# Iterate through each directory looking for a Dockerfile
for dir in */; do
  if [ -f "${dir}Dockerfile" ]; then
    # Remove the trailing slash from the directory name
    service_name=${dir%/}
    # Add the service name and port to the services array
    services+=("${service_name}:${port}")
    # Print the added service in table format
    printf "| %-20s | %-5s |\n" "$service_name" "$port"
    # Generate a docker-compose.yml for the service with . as build path
    service_definition=$(echo "$SERVICE_TEMPLATE" | sed "s/{{service_name}}/$service_name/g" | sed "s/{{port}}/$startPort/g" | sed "s/{{build_path}}/./g")
    echo "$DOCKER_COMPOSE_HEADER
$service_definition
$QTAP_LOCAL_SERVICE" > "${service_name}/docker-compose.yml"
    # Increment the port
    port=$((port + 1))
  fi
done

# Print table footer
echo "-----------------------------------------"

# Start building the main docker-compose.yml content
DOCKER_COMPOSE_CONTENT="$DOCKER_COMPOSE_HEADER"

# Add the geoweather services with service_name/. as build path
for service in "${services[@]}"; do
  service_name="${service%%:*}"
  port="${service##*:}"
  service_definition=$(echo "$SERVICE_TEMPLATE" | sed "s/{{service_name}}/$service_name/g" | sed "s/{{port}}/$port/g" | sed "s/{{build_path}}/${service_name}\//g")
  DOCKER_COMPOSE_CONTENT="$DOCKER_COMPOSE_CONTENT
$service_definition"
done

# Add the qtap.local service
DOCKER_COMPOSE_CONTENT="$DOCKER_COMPOSE_CONTENT
$QTAP_LOCAL_SERVICE"

# Write the content to the main docker-compose.yml
echo "$DOCKER_COMPOSE_CONTENT" > docker-compose.yml

echo "docker-compose.yml generated successfully."
