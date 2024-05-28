> NOTE: This is not currently working

# TerminalGPT

This is a simple chat GPT like in the terminal.


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
cd demos/apps/terminalgpt
```

### 4. Build & Start the Docker Container
Within the terminalgpt directory of your choosing, run the following command to build and run the application.

> Note: If you used an address other than "localhost," make sure to update those values in this command.

```
docker build -t terminalgpt . && \
    docker run -it --rm \
    --network host \
    -e HTTP_PROXY=http://localhost:10080 \
    terminalgpt
```

> Note: This command uses the host machine's network to provide access to the published ports in the Qpoint container. 

## License

This project is licensed under the Apache-2.0 License.
