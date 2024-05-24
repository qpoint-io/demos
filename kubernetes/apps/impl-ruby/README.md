# Ruby HTTP Client with Optional CA Certificate Injection

## Overview
This Ruby script is a command-line tool for making HTTP or HTTPS GET requests. It includes an optional feature to use a custom CA (Certificate Authority) certificate for SSL/TLS verification, useful for self-signed certificates or certificates from a private CA. The script also automatically respects `HTTP_PROXY` and `HTTPS_PROXY` environment variables.

## Requirements
- Ruby (preferably a recent version)

## Installation
No specific installation steps are required other than having Ruby installed on your system. Simply download or clone the script to your local machine.

## Usage
The script can be run in two modes:
1. **Basic Mode:** Make an HTTP or HTTPS GET request without a custom CA certificate.
2. **CA Certificate Mode:** Make an HTTP or HTTPS GET request with a custom CA certificate.

### Basic Mode
```
ruby app.rb [URL]
```
Replace `[URL]` with the desired HTTP or HTTPS URL.

### CA Certificate Mode
```
ruby app.rb [URL] [CA-Certificate-File]
```
- Replace `[URL]` with the desired HTTP or HTTPS URL.
- Replace `[CA-Certificate-File]` with the path to your CA certificate file.

## Proxy Support
If `HTTP_PROXY` or `HTTPS_PROXY` environment variables are set, the script will use these proxies for making the requests. Set these environment variables in your shell to use a proxy.

## Examples
1. Basic Mode:
   ```
   ruby app.rb https://example.com
   ```
2. CA Certificate Mode:
   ```
   ruby app.rb https://example.com /path/to/ca-cert.pem
   ```

## Note
- The CA certificate file should be in PEM format.
- The script handles both HTTP and HTTPS protocols and respects proxy settings defined in environment variables.
