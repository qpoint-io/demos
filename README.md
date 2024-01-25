# Qpoint Demos

A collection of apps and helpers to quickly spin up demos

## Setup

Ensure you have all the necessary dependencies:

```bash
make ensure-deps
```

Then build the necessary resources and images:

```bash
make build
```

## Usage

Check to see which apps are available:

```bash
make help
```

Bring up an app:

```bash
make <app>-app

# for example
make gpt4-app
```

Teardown when complete

```bash
make down
```
