#!/bin/bash

OWM_API_KEY="56e9e892982ed4de87fb7d8a6f470463"

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
    location=$(curl -s "https://ipapi.co/${ip}/json/")
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
    weather=$(curl -s "https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${OWM_API_KEY}&units=metric")
    if [ -z "$weather" ]; then
        echo "Unable to get weather"
        exit 1
    fi
    echo "$weather"
}

# Main function to fetch and display weather information
main() {
    echo "Starting weather function"

    local public_ip
    public_ip=$(get_public_ip)
    echo "Public IP fetched: $public_ip"

    local location
    location=$(get_location "$public_ip")
    echo "Location fetched for IP $public_ip: $location"

    local city country latitude longitude
    city=$(echo "$location" | jq -r .city)
    country=$(echo "$location" | jq -r .country_name)
    latitude=$(echo "$location" | jq -r .latitude)
    longitude=$(echo "$location" | jq -r .longitude)

    if [ -z "$latitude" ] || [ -z "$longitude" ]; then
        echo "Error fetching location data for IP: $public_ip"
        exit 1
    fi

    local weather
    weather=$(get_weather "$latitude" "$longitude")
    echo "Weather fetched for location $latitude, $longitude: $weather"

    local description temperature
    description=$(echo "$weather" | jq -r .weather[0].description)
    temperature=$(echo "$weather" | jq -r .main.temp)

    echo -e "\nWeather for $city, $country"
    echo "Current weather: $description"
    echo "Temperature: ${temperature}°C"
}

main
