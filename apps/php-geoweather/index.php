<?php
// Enable error logging
ini_set('log_errors', 1);
ini_set('error_log', '/var/www/html/error.log');
error_reporting(E_ALL);

function log_message($message) {
    error_log($message);
}

function get_public_ip() {
    log_message("Fetching public IP...");
    $response = file_get_contents('https://httpbin.org/ip');
    if ($response === false) {
        log_message("Error fetching public IP.");
        return null;
    }
    $data = json_decode($response, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        log_message("Error decoding public IP response: " . json_last_error_msg());
        return null;
    }
    log_message("Public IP fetched: " . $data['origin']);
    return $data['origin'];
}

function get_location($ip) {
    log_message("Fetching location for IP: " . $ip);
    $url = "http://ip-api.com/json/{$ip}";
    $response = file_get_contents($url);
    if ($response === false) {
        log_message("Error fetching location.");
        return null;
    }
    $location = json_decode($response, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        log_message("Error decoding location response: " . json_last_error_msg());
        return null;
    }
    log_message("Location fetched: " . print_r($location, true));
    return $location;
}

function get_weather($lat, $lon, $api_key) {
    log_message("Fetching weather for lat: " . $lat . " lon: " . $lon);
    $url = "https://api.openweathermap.org/data/2.5/weather?lat={$lat}&lon={$lon}&appid={$api_key}&units=metric";
    $response = file_get_contents($url);
    if ($response === false) {
        log_message("Error fetching weather.");
        return null;
    }
    $weather = json_decode($response, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        log_message("Error decoding weather response: " . json_last_error_msg());
        return null;
    }
    log_message("Weather fetched: " . print_r($weather, true));
    return $weather;
}
log_message("Loading PHP website...");

$owm_key = '56e9e892982ed4de87fb7d8a6f470463';
$weather = null;
$location = null;

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    log_message("Processing POST request...");
    $public_ip = get_public_ip();
    if ($public_ip) {
        $location = get_location($public_ip);
        if (isset($location['lat']) && isset($location['lon'])) {
            $weather = get_weather($location['lat'], $location['lon'], $owm_key);
        } else {
            log_message("Error fetching location data for IP: " . $public_ip);
        }
    } else {
        log_message("Error fetching public IP.");
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>GeoWeather App</title>
</head>
<body>
    <h1>Welcome to the GeoWeather App (PHP)</h1>
    <form action="/" method="POST">
        <button type="submit">Get My Weather</button>
    </form>

    <?php if ($_SERVER['REQUEST_METHOD'] == 'POST' && $weather && $location): ?>
        <h1>Weather for <?= htmlspecialchars($location['city']) ?>, <?= htmlspecialchars($location['country']) ?></h1>
        <p>Current weather: <?= htmlspecialchars($weather['weather'][0]['description']) ?></p>
        <p>Temperature: <?= htmlspecialchars($weather['main']['temp']) ?>°C</p>
        <a href="/">Back to home</a>
    <?php endif; ?>
</body>
</html>

