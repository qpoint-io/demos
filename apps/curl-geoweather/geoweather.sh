#!/usr/bin/env bash

# Ensure required commands are available
for cmd in curl jq; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is not installed."
        exit 1
    fi
done

# Function to get public IP
get_public_ip() {
    local ip
    ip=$(curl -s https://icanhazip.com)
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
    location=$(curl -s "https://ipwho.is/${ip}?fields=country,city,latitude,longitude,country_code")
    if [ -z "$location" ] || [ "$(echo "$location" | jq -r '.success')" == "false" ]; then
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
    weather=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current_weather=true")
    if [ -z "$weather" ] || [ "$(echo "$weather" | jq -r '.current_weather')" == "null" ]; then
        echo "Unable to get weather"
        exit 1
    fi
    echo "$weather"
}

# Function to get time zone information
get_timezone() {
    local lat="$1"
    local lon="$2"
    local timezone
    timezone=$(curl -s "http://worldtimeapi.org/api/timezone/Etc/GMT")
    if [ -z "$timezone" ]; then
        echo "Unable to get time zone"
        exit 1
    fi
    echo "$timezone"
}

# Function to get air quality information
get_air_quality() {
    local lat="$1"
    local lon="$2"
    local air_quality
    air_quality=$(curl -s "https://api.waqi.info/feed/geo:${lat};${lon}/?token=demo")
    if [ -z "$air_quality" ] || [ "$(echo "$air_quality" | jq -r '.status')" != "ok" ]; then
        echo "Unable to get air quality"
        exit 1
    fi
    echo "$air_quality"
}

# Function to get sunrise and sunset times
get_sunrise_sunset() {
    local lat="$1"
    local lon="$2"
    local sunrise_sunset
    sunrise_sunset=$(curl -s "https://api.sunrise-sunset.org/json?lat=${lat}&lng=${lon}&formatted=0")
    if [ -z "$sunrise_sunset" ] || [ "$(echo "$sunrise_sunset" | jq -r '.status')" != "OK" ]; then
        echo "Unable to get sunrise and sunset times"
        exit 1
    fi
    echo "$sunrise_sunset"
}

# Main function to fetch and display information
main() {
    echo "Starting location information function"

    local public_ip
    public_ip=$(get_public_ip)
    echo -e "\n1. Public IP fetched: $public_ip"

    local location
    location=$(get_location "$public_ip")

    local city country latitude longitude
    city=$(echo "$location" | jq -r .city)
    country=$(echo "$location" | jq -r .country)
    latitude=$(echo "$location" | jq -r .latitude)
    longitude=$(echo "$location" | jq -r .longitude)
    echo -e "\n2. Location fetched for IP $public_ip:\n\t$city, $country\n\t($latitude, $longitude)"

    if [ -z "$latitude" ] || [ -z "$longitude" ]; then
        echo "Error fetching location data for IP: $public_ip"
        exit 1
    fi

    local weather
    weather=$(get_weather "$latitude" "$longitude")
    local temperature
    temperature=$(echo "$weather" | jq -r .current_weather.temperature)

    echo -e "\n3. Weather for $city, $country"
    echo -e "\tTemperature: ${temperature}°C"

    local timezone
    timezone=$(get_timezone "$latitude" "$longitude")
    local local_time
    local_time=$(echo "$timezone" | jq -r .datetime)
    echo -e "\n4. Local Time for $city, $country"
    echo -e "\tLocal Time: ${local_time}"

    local air_quality
    air_quality=$(get_air_quality "$latitude" "$longitude")
    local aqi
    aqi=$(echo "$air_quality" | jq -r .data.aqi)
    echo -e "\n5. Air Quality for $city, $country"
    echo -e "\tAQI: ${aqi}"

    local sunrise_sunset
    sunrise_sunset=$(get_sunrise_sunset "$latitude" "$longitude")
    local sunrise sunset
    sunrise=$(echo "$sunrise_sunset" | jq -r .results.sunrise)
    sunset=$(echo "$sunrise_sunset" | jq -r .results.sunset)
    echo -e "\n6. Sunrise and Sunset times:\n\tSunrise: $sunrise\n\tSunset: $sunset"
}

main
