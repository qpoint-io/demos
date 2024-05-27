# Use a lightweight image with necessary tools
FROM alpine:latest

# Get latest CA's, cURL, and jq
ARG TOKEN
RUN apk --no-cache add curl jq bash ca-certificates && \
    curl -s https://api.qpoint.io/deploy/certificate -H "Authorization: Bearer $TOKEN" > /usr/local/share/ca-certificates/qpoint-ca.crt && \
    update-ca-certificates

# Set the working directory inside the container
WORKDIR /app

# Copy the Bash script into the container
COPY geoweather.sh .

# Ensure the script has execute permissions
RUN chmod +x geoweather.sh

# Run the Bash script when the container launches
CMD ["./geoweather.sh"]
