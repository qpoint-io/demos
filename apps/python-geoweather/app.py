from flask import Flask, request, render_template_string
import httpx
import logging

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.DEBUG)

async def get_public_ip():
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get('https://httpbin.org/ip')
            return response.json()['origin']
    except Exception as e:
        return "Unable to get public IP: " + str(e)

async def get_location(ip):
    url = f"http://ip-api.com/json/{ip}"
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        return response.json()

async def get_weather(lat, lon):
    url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m&forecast_days=1"
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        return response.json()

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
        <form action="/weather" method="POST">
            <button type="submit">Get My Weather</button>
        </form>
    </body>
    </html>
    """
    return render_template_string(html)

@app.route('/weather', methods=['POST'])
async def weather():
    logging.debug("Starting weather function")

    public_ip = await get_public_ip()
    logging.debug(f"Public IP fetched: {public_ip}")

    location = await get_location(public_ip)
    logging.debug(f"Location fetched for IP {public_ip}: {location}")

    if 'lat' in location and 'lon' in location:
        weather = await get_weather(location['lat'], location['lon'])
        logging.debug(f"Weather fetched for location {location['lat']}, {location['lon']}: {weather}")

        weather_html = f"""
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <title>Weather Result</title>
        </head>
        <body>
            <h1>Weather for {location['city']}, {location['country']} (Python)</h1>
            <p>Temperature: {weather['current']['temperature_2m']}°C</p>
            <a href="/">Back to home</a>
        </body>
        </html>
        """
        return render_template_string(weather_html)
    else:
        logging.error(f"Error fetching location data for IP: {public_ip}")
        return f"Error fetching location data for IP: {public_ip}"

if __name__ == "__main__":
    import asyncio
    app.run(host='0.0.0.0', port=80)

