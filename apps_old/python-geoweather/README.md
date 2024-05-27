# GeoWeather App (Python)

A simple web application that displays the weather for the user's current location based on their IP address. The app is built using Python and demonstrates how to make HTTP requests and render HTML templates.

## Prerequisites

- Docker
- Docker Compose

## Running the Application

### 1. Clone the repository

```bash
git clone https://github.com/qpoint-io/demos.git
cd demos/apps/python-geoweather
```

### 2. Set up the environment

Ensure you have a valid `TOKEN` from the [Qpoint Control Plane](https://app.qpoint.io/endpoints). You will need to set this environment variable in the `docker-compose.yml` file.

### 3. Docker Compose

The application is containerized using Docker and Docker Compose. The provided `docker-compose.yml` file will set up the necessary containers.

### 4. Build and run

```bash
TOKEN=<Qpoint_JQT> docker-compose up --build
```

This will build the Docker image for the Python application and start the necessary containers. The application will be accessible at `http://localhost:4000`.

## Application Structure

- `app.py`: The main application file.
- `Dockerfile`: Docker configuration for the application.
- `docker-compose.yml`: Docker Compose configuration.

## License

This project is licensed under the Apache-2.0 License.
