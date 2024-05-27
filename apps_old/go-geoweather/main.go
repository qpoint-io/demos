package main

import (
	"encoding/json"
	"fmt"
	"html/template"
	"log"
	"net/http"
)

type IPResponse struct {
	Origin string `json:"origin"`
}

type LocationResponse struct {
	City        string  `json:"city"`
	CountryName string  `json:"country_name"`
	Latitude    float64 `json:"lat"`
	Longitude   float64 `json:"lon"`
}

type WeatherResponse struct {
	Current struct {
		Temp float64 `json:"temperature_2m"`
	} `json:"current"`
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
	url := fmt.Sprintf("http://ip-api.com/json/%s", ip)
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
	url := fmt.Sprintf("https://api.open-meteo.com/v1/forecast?latitude=%f&longitude=%f&current=temperature_2m&forecast_days=1", lat, lon)
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
		<p>Temperature: {{.Temperature}}°C</p>
		<a href="/">Back to home</a>
	</body>
	</html>
	`

	data := struct {
		City        string
		CountryName string
		Temperature float64
	}{
		City:        location.City,
		CountryName: location.CountryName,
		Temperature: weather.Current.Temp,
	}

	tmpl := template.Must(template.New("weather").Parse(weatherHTML))
	tmpl.Execute(w, data)
}

func main() {
	http.HandleFunc("/", indexHandler)
	http.HandleFunc("/weather", weatherHandler)

	log.Println("Starting go-geoweather http server...")
	log.Fatal(http.ListenAndServe(":4000", nil))
}
