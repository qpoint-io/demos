# HTTP Client with Optional CA Certificate Injection in Go

## Overview
This Go program is a command-line tool that makes an HTTP GET request to a specified URL. It is capable of using a custom CA (Certificate Authority) certificate, if provided, to establish trust with the server during the TLS handshake. This feature is particularly useful when dealing with self-signed certificates or certificates signed by a private CA. The script also automatically respects `HTTP_PROXY` and `HTTPS_PROXY` environment variables.

## Requirements
- Go (version 1.11 or later)

## Installation
Clone the repository or download the source code to your local machine.

## Usage
The program can be run in two modes:
1. **Basic Mode:** Make an HTTP GET request without custom CA certificate.
2. **CA Certificate Mode:** Make an HTTP GET request with a custom CA certificate.

### Basic Mode
```
go run main.go [URL]
```
Replace `[URL]` with the desired HTTP/HTTPS URL.

### CA Certificate Mode
```
go run main.go [URL] [CA-Certificate-File]
```
- Replace `[URL]` with the desired HTTP/HTTPS URL.
- Replace `[CA-Certificate-File]` with the path to your CA certificate file.

## Proxy Support
If you have an HTTP or HTTPS proxy set up in your environment, the script can use it. Set the `HTTP_PROXY` or `HTTPS_PROXY` environment variables to your proxy server's URL.

```
export HTTP_PROXY=http://proxyserver:port
export HTTPS_PROXY=https://proxyserver:port
```

## Example
1. Basic Mode:
   ```
   go run main.go https://example.com
   ```
2. CA Certificate Mode:
   ```
   go run main.go https://example.com /path/to/ca-cert.pem
   ```

## Note
The program, in CA Certificate Mode, expects the CA certificate file to be in PEM format.
