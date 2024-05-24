package main

import (
	"encoding/json"
	"fmt"
	"html/template"
	"log"
	"net/http"
)

const owmAPIKey = "56e9e892982ed4de87fb7d8a6f470463"

type IPResponse struct {
	Origin string `json:"origin"`
}

type LocationResponse struct {
	City        string  `json:"city"`
	CountryName string  `json:"country_name"`
	Latitude    float64 `json:"latitude"`
	Longitude   float64 `json:"longitude"`
}

type WeatherResponse struct {
	Weather []struct {
		Description string `json:"description"`
	} `json:"weather"`
	Main struct {
		Temp float64 `json:"temp"`
	} `json:"main"`
}

func getPublicIP() (string, error) {
	resp, err := http.Get("https://httpbin.org/ip")
	if err != nil {
		return "", fmt.Errorf("unable to get public IP: %v", err)
	}
	defer resp.Body.Close()

	var ipResp IPResponse
	if err := json.NewDecoder(resp.Body).Decode(&ipResp); err != nil {
		return "", fmt.Errorf("unable to parse IP response: %v", err)
	}

	return ipResp.Origin, nil
}

func getLocation(ip string) (LocationResponse, error) {
	url := fmt.Sprintf("https://ipapi.co/%s/json/", ip)
	resp, err := http.Get(url)
	if err != nil {
		return LocationResponse{}, fmt.Errorf("unable to get location: %v", err)
	}
	defer resp.Body.Close()

	var locResp LocationResponse
	if err := json.NewDecoder(resp.Body).Decode(&locResp); err != nil {
		return LocationResponse{}, fmt.Errorf("unable to parse location response: %v", err)
	}

	return locResp, nil
}

func getWeather(lat, lon float64) (WeatherResponse, error) {
	url := fmt.Sprintf("https://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f&appid=%s&units=metric", lat, lon, owmAPIKey)
	resp, err := http.Get(url)
	if err != nil {
		return WeatherResponse{}, fmt.Errorf("unable to get weather: %v", err)
	}
	defer resp.Body.Close()

	var weatherResp WeatherResponse
	if err := json.NewDecoder(resp.Body).Decode(&weatherResp); err != nil {
		return WeatherResponse{}, fmt.Errorf("unable to parse weather response: %v", err)
	}

	return weatherResp, nil
}

func indexHandler(w http.ResponseWriter, r *http.Request) {
	html := `
	<!DOCTYPE html>
	<html lang="en">
	<head>
		<meta charset="UTF-8">
		<title>GeoWeather App</title>
	</head>
	<body>
		<h1>Welcome to the GeoWeather App (Go)</h1>
		<form action="/weather" method="POST">
			<button type="submit">Get My Weather</button>
		</form>
	</body>
	</html>
	`
	fmt.Fprint(w, html)
}

func weatherHandler(w http.ResponseWriter, r *http.Request) {
	log.Println("Starting weather function")

	publicIP, err := getPublicIP()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	log.Printf("Public IP fetched: %s", publicIP)

	location, err := getLocation(publicIP)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	log.Printf("Location fetched for IP %s: %v", publicIP, location)

	weather, err := getWeather(location.Latitude, location.Longitude)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	log.Printf("Weather fetched for location %f, %f: %v", location.Latitude, location.Longitude, weather)

	weatherHTML := `
	<!DOCTYPE html>
	<html lang="en">
	<head>
		<meta charset="UTF-8">
		<title>Weather Result</title>
	</head>
	<body>
		<h1>Weather for {{.City}}, {{.CountryName}} (Go)</h1>
		<p>Current weather: {{.WeatherDescription}}</p>
		<p>Temperature: {{.Temperature}}°C</p>
		<a href="/">Back to home</a>
	</body>
	</html>
	`

	data := struct {
		City               string
		CountryName        string
		WeatherDescription string
		Temperature        float64
	}{
		City:               location.City,
		CountryName:        location.CountryName,
		WeatherDescription: weather.Weather[0].Description,
		Temperature:        weather.Main.Temp,
	}

	tmpl := template.Must(template.New("weather").Parse(weatherHTML))
	tmpl.Execute(w, data)
}

func main() {
	http.HandleFunc("/", indexHandler)
	http.HandleFunc("/weather", weatherHandler)

	log.Println("Starting go-geoweather http server...")
	log.Fatal(http.ListenAndServe(":80", nil))
}
