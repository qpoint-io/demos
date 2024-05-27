# Qpoint Simple Docker Apps

This directory contains a series of demo apps that show how easy it is to use different programming languages with Qpoint and integration with the Qpoint Control Plane. 

## Prerequisites

- Docker
- Docker Compose

## Running *all* of the demos

### 1. Clone the repository

```bash
git clone https://github.com/qpoint-io/demos.git
cd demos/apps
```

### 2. Set up the environment

Ensure you have a valid `TOKEN` from the [Qpoint Control Plane](https://app.qpoint.io/endpoints). You will need to set this environment variable in the `docker-compose.yml` file.

### 3. Docker Compose

These applications are containerized using Docker and Docker Compose. The provided `docker-compose.yml` file will build and start all of the demo applications. Assigning them port forwards starting at 4000, incrementing by 1. 

### 4. Build and run

```bash
QPOINT_HTTP_PROXY=http://qpoint.local:10080 \
QPOINT_HTTPS_PROXY=http://qpoint.local:10443 \
TOKEN=<Qpoint_JQT> \
docker-compose up --build
```

This will build all of app images and start those containers with Qpoint proxy. Applications are given a port forward in the 4000 range and are available for access. All apps can be access simultaneously and the traffic will be reported to Qpoint. 

## License

This project is licensed under the Apache-2.0 License.
