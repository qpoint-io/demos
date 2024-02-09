import http from 'http';
import https from 'https';
import fs from 'fs';
import url from 'url';
import { HttpsProxyAgent } from 'https-proxy-agent';

// Check if the URL argument is provided
if (process.argv.length < 3) {
    console.log('Usage: node app.js [URL] [optional: ca-certificate-file]');
    process.exit(1);
}

// Get the URL from the command line arguments
const requestUrl = process.argv[2];

// Function to make the HTTP/HTTPS request
const makeRequest = (options, ca) => {
    // Check for proxy environment variables
    const proxy = process.env.HTTPS_PROXY || process.env.HTTP_PROXY;

    if (proxy) {
        options.agent = new HttpsProxyAgent(proxy);
    }

    // If a CA is provided, add it to the options
    if (ca) {
        options.ca = ca;
    }

    const protocol = options.protocol === 'https:' ? https : http;
    const req = protocol.request(options, (res) => {
        console.log(`STATUS: ${res.statusCode}`);
        console.log(`HEADERS: ${JSON.stringify(res.headers, null, 4)}`);

        res.on('end', () => {
            console.log('No more data in response.');
            process.exit(0);
        });
    });

    req.on('error', (e) => {
        console.error(`Problem with request: ${e.message.replace(/\n|\r/g, "")}`);
        process.exit(1);
    });

    req.end();
};

// Parse the URL
const options = url.parse(requestUrl);

// Check if a CA certificate file is provided
if (process.argv.length === 4) {
    const caCertFile = process.argv[3];
    fs.readFile(caCertFile, (err, data) => {
        if (err) {
            console.error(`Error reading CA certificate file: ${err.message}`);
            process.exit(1);
        }
        makeRequest(options, data);
    });
} else {
    makeRequest(options);
}

