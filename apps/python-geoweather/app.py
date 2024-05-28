from flask import Flask, request, render_template_string
import requests
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

app = Flask(__name__)

def get_public_ip():
    try:
        response = requests.get('https://icanhazip.com')
        response.raise_for_status()  # Will raise an HTTPError for bad responses
        return response.text.strip()
    except requests.HTTPError as http_err:
        logging.error(f'HTTP error occurred: {http_err}')  # HTTP error
        return f"Unable to get public IP: HTTP error occurred: {http_err}"
    except Exception as err:
        logging.error(f'Other error occurred: {err}')  # Other errors
        return f"Unable to get public IP: Other error occurred: {err}"

def get_location(ip):
    url = f"https://ipwho.is/{ip}?fields=country,city,latitude,longitude"
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response.json()
    except requests.HTTPError as http_err:
        logging.error(f'HTTP error occurred while fetching location: {http_err}')
        return {'error': f"HTTP error occurred: {http_err}"}
    except Exception as err:
        logging.error(f'Error fetching location: {err}')
        return {'error': f"Other error occurred: {err}"}

def get_weather(lat, lon):
    url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m&forecast_days=1"
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response.json()
    except requests.HTTPError as http_err:
        logging.error(f'HTTP error occurred while fetching weather: {http_err}')
        return {'error': f"HTTP error occurred: {http_err}"}
    except Exception as err:
        logging.error(f'Error fetching weather: {err}')
        return {'error': f"Other error occurred: {err}"}

@app.route('/')
def index():
    html = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>GeoWeather App</title>
    </head>
    <body>
        <h1>Welcome to the GeoWeather App (Python)</h1>
        <form action="/weather" method="post">
            <button type="submit">Get My Weather</button>
        </form>
    </body>
    </html>
    """
    return render_template_string(html)

@app.route('/weather', methods=['POST'])
def weather():
    public_ip = get_public_ip()

    if "Unable to get public IP" in public_ip:
        return f"<p>Error: {public_ip}</p>"

    location = get_location(public_ip)
    if 'error' in location:
        return f"<p>Error fetching location data for IP {public_ip}: {location['error']}</p>"

    weather = get_weather(location['latitude'], location['longitude'])
    if 'error' in weather:
        return f"<p>Error fetching weather data: {weather['error']}</p>"

    weather_html = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Weather Result</title>
    </head>
    <body>
        <h1>Weather for {location['city']}, {location['country']}</h1>
        <p>Temperature: {weather['current']['temperature_2m']}°C</p>
        <a href="/">Back to home</a>
    </body>
    </html>
    """
    return render_template_string(weather_html)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=4000)
