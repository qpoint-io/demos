#!/bin/bash

# Function to get public IP
get_public_ip() {
    local ip
    ip=$(curl -s https://httpbin.org/ip | jq -r .origin)
    if [ -z "$ip" ]; then
        echo "Unable to get public IP"
        exit 1
    fi
    echo "$ip"
}

# Function to get location from IP
get_location() {
    local ip="$1"
    local location
    location=$(curl -s "http://ip-api.com/json/{$ip}")
    if [ -z "$location" ]; then
        echo "Unable to get location"
        exit 1
    fi
    echo "$location"
}

# Function to get weather from latitude and longitude
get_weather() {
    local lat="$1"
    local lon="$2"
    local weather
    weather=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m&forecast_days=1")
    if [ -z "$weather" ]; then
        echo "Unable to get weather"
        exit 1
    fi
    echo "$weather"
}

# Function to check if the service is ready
check_ready() {
    if [ -z "$HTTPS_PROXY" ]; then
        echo "> HTTPS_PROXY environment variable is not set. Skipping."
        return 0
    fi

    local max_retries=60
    local retry_count=0
    local status

    while [ $retry_count -lt $max_retries ]; do
        status=$(curl -s http://qpoint.local:10001/readyz)
        if [ "$status" == "ready" ]; then
            echo "Service is ready"
            return 0
        fi
        echo "Service not ready, retrying in 1 second... $status"
        sleep 1
        ((retry_count++))
    done

    echo "Service did not become ready in time"
    exit 1
}



# Main function to fetch and display weather information
main() {
    echo "Starting weather function"

    # Check if the service is ready
    check_ready

    local public_ip
    public_ip=$(get_public_ip)
    echo -e "\n1. Public IP fetched: $public_ip"

    local location
    location=$(get_location "$public_ip")

    local city country latitude longitude
    city=$(echo "$location" | jq -r .city)
    country=$(echo "$location" | jq -r .country)
    latitude=$(echo "$location" | jq -r .lat)
    longitude=$(echo "$location" | jq -r .lon)
    echo -e "\n2. Location fetched for IP $public_ip:\n\t$city, $country\n\t($latitude, $longitude)"

    if [ -z "$latitude" ] || [ -z "$longitude" ]; then
        echo "Error fetching location data for IP: $public_ip"
        exit 1
    fi

    local weather
    weather=$(get_weather "$latitude" "$longitude")
    local description temperature
    temperature=$(echo "$weather" | jq -r .current.temperature_2m)

    echo -e "\n3. Weather for $city, $country"
    echo -e "\tTemperature: ${temperature}°C"
}

main
