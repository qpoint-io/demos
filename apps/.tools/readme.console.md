<!--

Warning: This is a generated file. Do Not Edit.

-->
# GeoWeather App ({{service_language}})

A simple demo application that displays the weather for the user's current location based on their IP address. The app is built using `{{service_language}}` and accepts `HTTP_PROXY` and `HTTPS_PROXY` environment variables for interacting with QPoint.

## Prerequisites

- Git
- Docker

## Running the Application

### 1. Setup a Qpoint Qproxy
This demo utilizes the Qpoint Control Plane and requires a free Qpoint account.

1. Head over to [Qpoint](https://qpoint.io) and sign up for an account.
2. Click the `+ Go` button on the nav bar.
3. Select the `Deploy Qproxy` option.
4. Select `Docker`.
5. Copy the provided Docker run command and execute it in a terminal.
6. Set the Address, `localhost` is probably fine for this example.

At this point, you'll have a running Qpoint proxy ready to take on traffic!

### 2. Connect an App to a Transparent Qpoint Proxy

1. On the [Qpoint Dashboard](https://qpoint.io), select `+ Go`.
2. Select `Connect an App` on the right side of the menu.
3. Select the `Proxy Environment Variable` option.
4. Select the `Transparent Proxy` option.
5. Make a note of the HTTP and HTTPS proxy URLs.

### 3. Clone the Repository

```
git clone https://github.com/qpoint-io/demos.git
cd demos/apps/{{service_name}}
```

### 4. Build & Start the Docker Container
Within an app directory of your choosing, run the following command to build and run the application.

> Note: If you used an address other than "localhost," make sure to update those values in this command.

```
docker build -t {{service_name}} . && \
    docker run -it --rm \
    --network host \
    -e http_proxy=http://localhost:18080 \
    -e HTTP_PROXY=http://localhost:18080 \
    -e HTTPS_PROXY=http://localhost:18443 \
    {{service_name}}
```

> Note: This command uses the host machine's network to provide access to the published ports in the Qpoint container. 

### 5. Test the App

This app will output details to console, they may look something like:

```bash
Starting weather function
> HTTPS_PROXY environment variable is not set. Skipping.

1. Public IP fetched: 172.217.22.14

2. Location fetched for IP 172.217.22.14:
        Vancouver, Canada
        (49.2827, -123.1207)

3. Weather for Edmonton, Canada
        Temperature: 16.9°C
```

### 6. Review Traffic

This app reaches out to various APIs to retrieve your remote IP, geo-IP location, and weather data. Navigating to the [Qpoint Traffic Dashboard](https://qpoint.io) will display the domain URLs being accessed by the application. Each domain is clickable and will let you dive into the traffic for each.

## License

This project is licensed under the Apache-2.0 License.
