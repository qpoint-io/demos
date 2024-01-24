package main

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"net/http"
	"net/http/httputil"
	"os"
)

func main() {
	// Check if a URL argument is provided
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run main.go [url] [optional: ca-certificate-file]")
		os.Exit(1)
	}

	// Get the URL from the command line arguments
	url := os.Args[1]

	// Set up HTTP transport that respects HTTP_PROXY and HTTPS_PROXY
	transport := &http.Transport{
		Proxy: http.ProxyFromEnvironment,
	}

	// Check if a CA certificate file is provided
	if len(os.Args) == 3 {
		caCertFile := os.Args[2]

		// Load the CA certificate
		caCert, err := os.ReadFile(caCertFile)
		if err != nil {
			fmt.Printf("Error reading CA certificate file: %v\n", err)
			os.Exit(1)
		}

		// Append the CA certificate to the system's pool of trusted certificates
		caCertPool := x509.NewCertPool()
		if !caCertPool.AppendCertsFromPEM(caCert) {
			fmt.Println("Failed to append CA certificate")
			os.Exit(1)
		}

		// Create a custom TLS config with the updated pool of certificates
		tlsConfig := &tls.Config{
			RootCAs: caCertPool,
		}

		// Update the transport with the custom TLS config
		transport.TLSClientConfig = tlsConfig
	}

	// Create an HTTP client with the transport
	client := &http.Client{Transport: transport}

	// Create a new HTTP request
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		fmt.Printf("Error creating request: %v\n", err)
		os.Exit(1)
	}

	// Dump the HTTP request to stdout
	dumpReq, err := httputil.DumpRequestOut(req, false)
	if err != nil {
		fmt.Printf("Error dumping request: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Request:\n%s\n\n", dumpReq)

	// Perform the HTTP request
	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("Error sending request: %v\n", err)
		os.Exit(1)
	}
	defer resp.Body.Close()

	// Dump the HTTP response to stdout
	dumpResp, err := httputil.DumpResponse(resp, false)
	if err != nil {
		fmt.Printf("Error dumping response: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Response:\n%s\n", dumpResp)
}
