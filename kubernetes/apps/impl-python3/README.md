# Python HTTP Client with Optional CA Certificate Injection

## Overview
This Python script is a command-line tool for making HTTP or HTTPS GET requests. It includes an optional feature to use a custom CA (Certificate Authority) certificate for SSL/TLS verification, which is useful when dealing with self-signed certificates or certificates signed by a private CA. The script also supports HTTP and HTTPS proxies through environment variables.

## Requirements
- Python 3.x

## Installation
No specific installation steps are required other than having Python 3.x installed on your system. Simply download or clone the script to your local machine.

## Usage
The script can be run in two modes:
1. **Basic Mode:** Make an HTTP or HTTPS GET request without a custom CA certificate.
2. **CA Certificate Mode:** Make an HTTP or HTTPS GET request with a custom CA certificate.

### Basic Mode
```
python3 app.py [URL]
```
Replace `[URL]` with the desired HTTP or HTTPS URL.

### CA Certificate Mode
```
python3 app.py [URL] [CA-Certificate-File]
```
- Replace `[URL]` with the desired HTTP or HTTPS URL.
- Replace `[CA-Certificate-File]` with the path to your CA certificate file in PEM format.

## Proxy Support
If you have an HTTP or HTTPS proxy set up in your environment, the script can use it. Set the `HTTP_PROXY` or `HTTPS_PROXY` environment variables to your proxy server's URL.

```
export HTTP_PROXY=http://proxyserver:port
export HTTPS_PROXY=https://proxyserver:port
```

## Examples
1. Basic Mode:
   ```
   python3 app.py https://example.com
   ```
2. CA Certificate Mode:
   ```
   python3 app.py https://example.com /path/to/ca-cert.pem
   ```

## Note
- The CA certificate file should be in PEM format.
- The script handles both HTTP and HTTPS protocols and supports proxy settings through environment variables.

