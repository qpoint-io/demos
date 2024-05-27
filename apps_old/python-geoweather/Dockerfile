# Use an official Python runtime as a parent image
FROM python:3.12-slim

# Get latest CA's
ARG TOKEN
RUN apt-get update && \
    apt-get install -y curl ca-certificates && \
    curl -s https://api.qpoint.io/deploy/certificate -H "Authorization: Bearer $TOKEN" > /usr/local/share/ca-certificates/qpoint-ca.crt && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*


# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . .

# Install any needed packages specified in requirements.txt
RUN pip install Flask[async] requests httpx h2

# Set environment variables for the proxy
# ENV http_proxy http://qpoint.local:18080
# ENV https_proxy http://qpoint.local:18443

# Make port 80 available to the world outside this container
EXPOSE 80

# Define environment variable
ENV NAME World

# Run app.py when the container launches
CMD ["python", "app.py"]
