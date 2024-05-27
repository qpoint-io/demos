# Use a lightweight image with necessary tools
FROM alpine:latest

# Install curl and jq
RUN apk --no-cache add curl jq bash ca-certificates

# Set the working directory inside the container
WORKDIR /app

# Copy the Bash script into the container
COPY geoweather.sh .

# Ensure the script has execute permissions
RUN chmod +x geoweather.sh

# Run the Bash script when the container launches
CMD ["./geoweather.sh"]
