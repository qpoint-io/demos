#!/usr/bin/env bash

# Ensure required commands are available
for cmd in curl jq; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is not installed." >&2
        exit 1
    fi
done

# Function to get public IP
get_public_ip() {
    local ip
    local response
    local status_code
    local curl_command

    # Check for HTTPS_PROXY environment variable
    if [ -n "$HTTPS_PROXY" ]; then
        echo "✓ HTTPS Proxy detected" >&2
    else
        echo "✗ No HTTPS Proxy detected" >&2
    fi

    if [ "$1" == "--ratelimit" ]; then
        # Simulate rate limiting
        curl_command="curl -s -k -o /dev/null -w '%{http_code}' -X GET 'https://httpbin.org/status/200%2C%20429' -H 'accept: text/plain'"

        response=$(eval "$curl_command")
        status_code=$response

        echo "Status code: $status_code" >&2

        if [ "$status_code" == "429" ]; then
            echo "Error: Public IP Unfetchable (Rate limited)" >&2
            return 1
        fi
        # Assume IP when 200 received
        ip="24.23.180.98"
    else
        # Regular IP fetch
        curl_command="curl -s -k -X GET 'https://httpbin.org/ip' -H 'accept: application/json'"

        response=$(eval "$curl_command")
        status_code=$(echo "$response" | jq -r '.status // "200"')

        echo "Status code: $status_code" >&2

        # Extract IP(s) from the response
        ip=$(echo "$response" | jq -r .origin)

        # Check if multiple IPs are present
        if [[ $ip == *","* ]]; then
            # Split the IP string and take the second IP
            ip=$(echo "$ip" | awk -F', ' '{print $2}')
            echo "Multiple IPs detected. Using: $ip" >&2
        fi

        if [ -z "$ip" ]; then
            echo "Unable to get public IP" >&2
            return 1
        fi
    fi
    echo "$ip"
}

# Function to get location from IP
get_location() {
    local ip="$1"
    local location
    location=$(curl -s -k "https://ipwho.is/${ip}")
    if [ -z "$location" ]; then
        echo "Unable to get location" >&2
        return 1
    fi
    
    # Check if the response is valid JSON
    if ! echo "$location" | jq empty; then
        echo "Invalid JSON response from location API" >&2
        return 1
    fi
    
    # Check if the response contains an error message
    if [ "$(echo "$location" | jq -r '.success // true')" == "false" ]; then
        local error_message=$(echo "$location" | jq -r '.message // "Unknown error"')
        echo "Error from location API: $error_message" >&2
        # Return a specific exit code for rate limiting
        if [[ "$error_message" == *"monthly limit"* ]]; then
            return 2
        fi
        return 1
    fi
    
    echo "$location"
}

# Function to get weather from latitude and longitude
get_weather() {
    local lat="$1"
    local lon="$2"
    local weather
    weather=$(curl -s -k "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current_weather=true")
    if [ -z "$weather" ] || [ "$(echo "$weather" | jq -r '.current_weather // null')" == "null" ]; then
        echo "Unable to get weather" >&2
        return 1
    fi
    echo "$weather"
}

# Function to get time zone information
get_timezone() {
    local lat="$1"
    local lon="$2"
    local timezone
    timezone=$(curl -s -k "http://worldtimeapi.org/api/timezone/Etc/GMT")
    if [ -z "$timezone" ]; then
        echo "Unable to get time zone" >&2
        return 1
    fi
    echo "$timezone"
}

# Function to get air quality information
get_air_quality() {
    local lat="$1"
    local lon="$2"
    local air_quality
    air_quality=$(curl -s -k "https://api.waqi.info/feed/geo:${lat};${lon}/?token=demo")
    if [ -z "$air_quality" ] || [ "$(echo "$air_quality" | jq -r '.status // "error"')" != "ok" ]; then
        echo "Unable to get air quality" >&2
        return 1
    fi
    echo "$air_quality"
}

# Function to get sunrise and sunset times
get_sunrise_sunset() {
    local lat="$1"
    local lon="$2"
    local sunrise_sunset
    sunrise_sunset=$(curl -s -k "https://api.sunrise-sunset.org/json?lat=${lat}&lng=${lon}&formatted=0")
    if [ -z "$sunrise_sunset" ] || [ "$(echo "$sunrise_sunset" | jq -r '.status // "ERROR"')" != "OK" ]; then
        echo "Unable to get sunrise and sunset times" >&2
        return 1
    fi
    echo "$sunrise_sunset"
}

# Main function to fetch and display information
#!/usr/bin/env bash

# ... (previous functions remain the same)

# Main function to fetch and display information
main() {
    local ratelimit_flag=$1
    echo "📍 Location Information"
    echo "----------------------"

    local public_ip
    public_ip=$(get_public_ip "$ratelimit_flag")
    if [ $? -ne 0 ]; then
        echo -e "\n🌐 Public IP: $public_ip"
        exit 1
    fi
    echo -e "\n🌐 Public IP: $public_ip"

    local location
    location=$(get_location "$public_ip")
    local location_status=$?
    
    echo "Debug: Location API response: $location" >&2
    
    if [ $location_status -ne 0 ] || [ "$(echo "$location" | jq -r '.success')" == "false" ]; then
        echo "The location API (ipwho.is) returned an error or hit rate limit." >&2
        echo "Defaulting to San Francisco, California coordinates." >&2
        city="San Francisco"
        country="United States"
        latitude="37.7749"
        longitude="-122.4194"
    else
        city=$(echo "$location" | jq -r '.city // "Unknown"')
        country=$(echo "$location" | jq -r '.country // "Unknown"')
        latitude=$(echo "$location" | jq -r '.latitude // "Unknown"')
        longitude=$(echo "$location" | jq -r '.longitude // "Unknown"')
    fi

    echo -e "📌 Location: $city, $country"
    echo -e "   Coordinates: ($latitude, $longitude)"

    local weather
    weather=$(get_weather "$latitude" "$longitude")
    if [ $? -ne 0 ]; then 
        echo "Unable to get weather data" >&2
    else
        local temperature
        temperature=$(echo "$weather" | jq -r '.current_weather.temperature // "Unknown"')

        echo -e "\n🌡️  Weather"
        echo -e "   Temperature: ${temperature}°C"
    fi

    local timezone
    timezone=$(get_timezone "$latitude" "$longitude")
    if [ $? -ne 0 ]; then 
        echo "Unable to get timezone data" >&2
    else
        local local_time
        local_time=$(echo "$timezone" | jq -r '.datetime // "Unknown"')

        echo -e "\n🕰️  Local Time: ${local_time}"
    fi

    local air_quality
    air_quality=$(get_air_quality "$latitude" "$longitude")
    if [ $? -ne 0 ]; then 
        echo "Unable to get air quality data" >&2
    else
        local aqi
        aqi=$(echo "$air_quality" | jq -r '.data.aqi // "Unknown"')

        echo -e "\n💨 Air Quality"
        echo -e "   AQI: ${aqi}"
    fi

    local sunrise_sunset
    sunrise_sunset=$(get_sunrise_sunset "$latitude" "$longitude")
    if [ $? -ne 0 ]; then 
        echo "Unable to get sunrise and sunset data" >&2
    else
        local sunrise
        sunrise=$(echo "$sunrise_sunset" | jq -r '.results.sunrise // "Unknown"')
        local sunset
        sunset=$(echo "$sunrise_sunset" | jq -r '.results.sunset // "Unknown"')

        echo -e "\n🌅 Sun Times"
        echo -e "   Sunrise: $sunrise"
        echo -e "   Sunset:  $sunset"
    fi
}

main "$@"