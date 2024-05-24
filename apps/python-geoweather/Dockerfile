# Use an official Python runtime as a parent image
FROM python:3.8-slim

# Get latest public CA's
RUN apt install -y ca-certificates


# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . .

# Install any needed packages specified in requirements.txt
RUN pip install Flask[async] requests httpx h2

# Set environment variables for the proxy
# ENV http_proxy http://qtap.local:18080
# ENV https_proxy http://qtap.local:18443

# Make port 80 available to the world outside this container
EXPOSE 80

# Define environment variable
ENV NAME World

# Run app.py when the container launches
CMD ["python", "app.py"]
