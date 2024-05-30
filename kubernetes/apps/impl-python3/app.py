import http.client
import ssl
import sys
import urllib.parse
import os

def make_request(url, ca_cert_file=None):
    parsed_url = urllib.parse.urlparse(url)
    proxy = os.environ.get('HTTPS_PROXY' if parsed_url.scheme == 'https' else 'HTTP_PROXY')

    context = ssl.create_default_context()
    if ca_cert_file:
        context.load_verify_locations(ca_cert_file)

    if proxy:
        proxy_parsed = urllib.parse.urlparse(proxy)

        print(f"Proxy URL: {proxy}")
        print(f"Proxy Host: {proxy_parsed.hostname}")
        print(f"Proxy Port: {proxy_parsed.port}")

        conn = http.client.HTTPSConnection if parsed_url.scheme == "https" else http.client.HTTPConnection
        connection = conn(proxy_parsed.hostname, proxy_parsed.port)
        connection.set_tunnel(parsed_url.netloc)
    else:
        conn = http.client.HTTPSConnection if parsed_url.scheme == "https" else http.client.HTTPConnection
        connection = conn(parsed_url.netloc, context=context if parsed_url.scheme == "https" else None)

    try:
        print(f"Sending request to {url}")
        connection.request("GET", parsed_url.path or '/')
        response = connection.getresponse()
        print(f"Received response from {url}")
        print(f"STATUS: {response.status}")
        print(f"HEADERS: {response.headers}")
        # print("BODY:")
        # print(response.read().decode())
    except Exception as e:
        print(f"Error making request: {e}")
    finally:
        connection.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 app.py [URL] [optional: ca-certificate-file]")
        sys.exit(1)

    url = sys.argv[1]
    ca_cert_file = sys.argv[2] if len(sys.argv) > 2 else None
    make_request(url, ca_cert_file)

