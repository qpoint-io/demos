# Use an official Python runtime as a parent image
FROM python:3.12-alpine

# Get latest CA's
ARG TOKEN
RUN apk --no-cache add curl ca-certificates && \
    if [ -n "$TOKEN" ]; then \
        curl -s https://api.qpoint.io/deploy/certificate -H "Authorization: Bearer $TOKEN" > /usr/local/share/ca-certificates/qpoint-ca.crt && \
        update-ca-certificates; \
    fi

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . .

# Install any needed packages specified in requirements.txt
RUN pip install flask requests

# Make port 4000 available to the world outside this container
EXPOSE 4000

# Run app.py when the container launches
CMD ["python", "app.py"]
